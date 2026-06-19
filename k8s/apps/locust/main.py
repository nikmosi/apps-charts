import random

import urllib3
from locust import HttpUser, between, task
from requests.exceptions import RequestException

# Отключаем предупреждения в логах о невалидных SSL сертификатах на целевых узлах
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# База: 60+ RU доменов (медиа, маркетплейсы, IT, порталы)
RU_DOMAINS = [
    "https://yandex.ru",
    "https://vk.com",
    "https://mail.ru",
    "https://dzen.ru",
    "https://avito.ru",
    "https://wildberries.ru",
    "https://ozon.ru",
    "https://rbc.ru",
    "https://lenta.ru",
    "https://ria.ru",
    "https://habr.com",
    "https://pikabu.ru",
    "https://kinopoisk.ru",
    "https://hh.ru",
    "https://auto.ru",
    "https://drom.ru",
    "https://vc.ru",
    "https://dtf.ru",
    "https://ixbt.com",
    "https://4pda.to",
    "https://sports.ru",
    "https://championat.com",
    "https://ok.ru",
    "https://rt.com",
    "https://gazeta.ru",
    "https://kommersant.ru",
    "https://vedomosti.ru",
    "https://kolesa.ru",
    "https://dns-shop.ru",
    "https://citilink.ru",
    "https://mvideo.ru",
    "https://eldorado.ru",
    "https://megamarket.ru",
    "https://lamoda.ru",
    "https://rutube.ru",
    "https://ivi.ru",
    "https://okko.tv",
    "https://premier.one",
    "https://matchtv.ru",
    "https://kp.ru",
    "https://mk.ru",
    "https://rg.ru",
    "https://is.ru",
    "https://fontanka.ru",
    "https://e1.ru",
    "https://yaplakal.com",
    "https://3dnews.ru",
    "https://thg.ru",
    "https://cnews.ru",
    "https://tproger.ru",
    "https://ya.market",
    "https://cian.ru",
    "https://domclick.ru",
    "https://gismeteo.ru",
    "https://pogoda.yandex.ru",
    "https://tutu.ru",
    "https://aviasales.ru",
    "https://sletat.ru",
    "https://eda.yandex.ru",
    "https://market.yandex.ru",
]

# База: Глобальные домены
GLOBAL_DOMAINS = [
    "https://en.wikipedia.org",
    "https://github.com",
    "https://stackoverflow.com",
    "https://reddit.com",
    "https://aliexpress.com",
    "https://twitch.tv",
    "https://youtube.com",
    "https://google.com",
    "https://bing.com",
    "https://yahoo.com",
    "https://amazon.com",
    "https://imdb.com",
    "https://bbc.com",
    "https://ubuntu.com",
    "https://nixos.org",
    "https://docker.com",
    "https://kubernetes.io",
    "https://gitlab.com",
    "https://news.ycombinator.com",
]

# Типовые пути для глубокого серфинга (сдвиг вероятности в сторону корня "/")
PATHS = [
    "/",
    "/",
    "/",
    "/",
    "/news",
    "/catalog",
    "/about",
    "/contacts",
    "/search",
    "/articles",
    "/blog",
    "/forum",
    "/video",
    "/sport",
    "/help",
    "/support",
    "/category",
    "/top",
    "/new",
]

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
]


class StealthSurfer(HttpUser):
    # Пауза между запросами: от 10 до 30 секунд.
    # При 10 пользователях это всего ~20-30 запросов в минуту в сумме на все 80+ доменов.
    wait_time = between(10.0, 30.0)

    @task
    def browse_deep_pages(self):
        domain = random.choice(RU_DOMAINS + GLOBAL_DOMAINS)
        path = random.choice(PATHS)
        target = f"{domain}{path}"

        headers = {
            "User-Agent": random.choice(USER_AGENTS),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
        }

        try:
            # verify=False спасает от падений из-за кривых SSL
            # catch_response=True позволяет Locust не воспринимать 403 от Cloudflare как краш
            with self.client.get(
                target, headers=headers, catch_response=True, timeout=15, verify=False
            ) as response:
                # Принудительно маркируем любые HTTP-ответы как успех
                response.success()
        except RequestException:
            # Тихо глушим обрывы TCP и ошибки разрешения DNS
            pass
