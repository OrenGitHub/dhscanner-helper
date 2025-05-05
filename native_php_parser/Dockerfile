FROM php
RUN apt-get update
RUN apt-get install zip -y
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN composer create-project laravel/laravel frontend
WORKDIR /frontend
COPY web.php routes/web.php
EXPOSE 5000
CMD [ "php", "artisan", "serve", "--host", "0.0.0.0", "--port", "5000" ]