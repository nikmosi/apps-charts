{
  inputs,
  pkgs,
  ...
}:

{
  packages = [
    pkgs.git
    pkgs.nushell
    pkgs.trufflehog
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.kustomize
    pkgs.kubeconform
    pkgs.kubernetes-validate
    pkgs.yamllint
    pkgs.yq-go
    pkgs.fluxcd
    pkgs.nixfmt
    pkgs.kind
    pkgs.k9s
  ];

  git-hooks.hooks = {
    nixfmt.enable = true;
    statix.enable = true;
    deadnix.enable = true;

    yamllint = {
      enable = true;
      excludes = [ "^k8s/.*/templates/" ];
      settings = {
        strict = true;
        configuration = ''
          extends: default

          rules:
            comments-indentation: disable
            document-start: disable
            indentation: disable
            line-length: disable
            truthy: disable
        '';
      };
    };

    kubernetes-manifests = {
      enable = true;
      name = "Kubernetes manifests";
      entry = "validate-kubernetes";
      files = "^k8s/.*\\.ya?ml$";
      excludes = [ "^k8s/.*/templates/" ];
      pass_filenames = true;
    };

    helm-charts = {
      enable = true;
      name = "Helm charts";
      entry = "validate-helm";
      files = "^k8s/.*/(Chart\\.yaml|Chart\\.lock|values.*\\.yaml|values\\.schema\\.json|templates/.*)$";
      pass_filenames = false;
    };

    kustomize-overlays = {
      enable = true;
      name = "Kustomize overlays";
      entry = "validate-kustomize";
      files = "^k8s/.*\\.ya?ml$";
      pass_filenames = false;
    };

    flux-manifests = {
      enable = true;
      name = "Flux manifests";
      entry = "validate-flux";
      files = "^k8s/.*\\.ya?ml$";
      pass_filenames = false;
    };

    trufflehog = {
      enable = true;
      name = "TruffleHog";
      entry = "env TRUFFLEHOG_PRE_COMMIT=1 trufflehog git file://.";
      pass_filenames = false;
    };
  };

  scripts.scan-secrets.exec = ''
    set -euo pipefail
    cd "$DEVENV_ROOT"

    exec trufflehog multi-scan \
      --config "$DEVENV_ROOT/.trufflehog.yaml" \
      --results=verified,unknown,unverified \
      --fail
  '';

  scripts.validate-rendered.exec = ''
    set -euo pipefail

    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT

    if (( $# > 0 )); then
      cat "$@" > "$tmp"
    else
      cat > "$tmp"
    fi

    kubernetes-validate --strict --quiet "$tmp"

    kubeconform \
      -strict \
      -summary \
      -ignore-missing-schemas \
      -schema-location '${inputs.crd-schemas}/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
      "$tmp"
  '';

  scripts.validate-kubernetes.exec = ''
    set -euo pipefail
    cd "$DEVENV_ROOT"

    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT

    if (( $# > 0 )); then
      files=("$@")
    else
      mapfile -d "" -t files < <(
        find k8s -type f \( -name '*.yaml' -o -name '*.yml' \) \
          ! -path '*/templates/*' -print0 | sort -z
      )
    fi

    resources=0
    for file in "''${files[@]}"; do
      [[ -f "$file" ]] || continue
      [[ "$file" == */templates/* ]] && continue

      rendered="$(yq eval-all \
        'select(tag == "!!map" and has("apiVersion") and has("kind"))' \
        "$file")"

      if [[ -n "$rendered" ]]; then
        printf '%s\n---\n' "$rendered" >> "$tmp"
        resources=$((resources + 1))
      fi
    done

    if (( resources == 0 )); then
      echo "No plain Kubernetes manifests to validate."
      exit 0
    fi

    validate-rendered "$tmp"
  '';

  scripts.validate-helm.exec = ''
    set -euo pipefail
    cd "$DEVENV_ROOT"

    mapfile -t charts < <(find k8s -name Chart.yaml -print | sort)

    for chart in "''${charts[@]}"; do
      directory="''${chart%/Chart.yaml}"
      release="$(basename "$directory")"

      echo "==> helm lint $directory"
      helm lint --strict "$directory"

      echo "==> helm template $directory"
      helm template "$release" "$directory" --include-crds | validate-rendered
    done
  '';

  scripts.validate-kustomize.exec = ''
    set -euo pipefail
    cd "$DEVENV_ROOT"

    mapfile -d "" -t files < <(
      find k8s -type f \
        \( -name kustomization.yaml -o -name kustomization.yml -o -name Kustomization \) \
        -print0 | sort -z
    )

    if (( ''${#files[@]} == 0 )); then
      echo "No Kustomize overlays to validate."
      exit 0
    fi

    for file in "''${files[@]}"; do
      directory="$(dirname "$file")"
      echo "==> kustomize build $directory"
      kustomize build "$directory" | validate-rendered
    done
  '';

  scripts.validate-flux.exec = ''
    set -euo pipefail
    cd "$DEVENV_ROOT"

    mapfile -d "" -t files < <(
      grep -rlZ \
        -E '^(apiVersion: (source|kustomize|helm|notification|image)\.toolkit\.fluxcd\.io/|kind: (GitRepository|OCIRepository|Bucket|Kustomization|HelmRelease|Alert|Provider|Receiver|ImageRepository|ImagePolicy|ImageUpdateAutomation)$)' \
        k8s --include='*.yaml' --include='*.yml' || true
    )

    if (( ''${#files[@]} == 0 )); then
      echo "No Flux resources to validate."
      exit 0
    fi

    validate-kubernetes "''${files[@]}"
  '';
}
