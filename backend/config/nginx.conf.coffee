
if process.env.NGINX_SSL_TERMINATION?.toLowerCase() == 'on'
  SSL_CONFIG_BLOCK = """
    ssl                  on;
    ssl_certificate      ../../certs/localhost.crt;
    ssl_certificate_key  ../../certs/localhost.key;
    ssl_session_timeout  5m;
    ssl_protocols  SSLv2 SSLv3 TLSv1;
    ssl_ciphers  ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
    ssl_prefer_server_ciphers   on;"""
  SSL_LOCATION_BLOCK = """
      error_page 497 https://$host:$server_port$request_uri;
      proxy_set_header  X-Client-Verify  SUCCESS;
      proxy_set_header  X-Client-DN      $ssl_client_s_dn;
      proxy_set_header  X-SSL-Subject    $ssl_client_s_dn;
      proxy_set_header  X-SSL-Issuer     $ssl_client_i_dn;
      proxy_set_header  X-Forwarded-Port $server_port;
      proxy_set_header  X-Forwarded-Proto https;"""
  SSL_LISTEN_CONFIG = 'ssl'
else
  SSL_CONFIG_BLOCK = ''
  SSL_LOCATION_BLOCK = ''
  SSL_LISTEN_CONFIG = ''


process.stdout.write """
daemon off;
worker_processes #{process.env.NGINX_WORKERS || 4};
pid ./nginx.pid;

events {
  use #{process.env.NGINX_CONNECTION_METHOD || "poll"};
  accept_mutex on;
  worker_connections 1024;
}

http {
  recursive_error_pages on;

  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 9;
  gzip_min_length 512;

  server_tokens off;

  log_format l2met 'measure#nginx.service=$request_time request_id=$http_x_request_id';
  access_log logs/nginx.access.log l2met;
  error_log logs/nginx.error.log;

  include mime.types;
  default_type application/octet-stream;
  sendfile on;

  # Increase default upload size from 1M to allow uploading larger images.
  client_max_body_size 10M;

  upstream app_server {
    server unix:./#{process.env.NGINX_SOCKET_FILENAME} fail_timeout=0;
  }

  server {
    listen #{process.env.PORT || 8085} #{SSL_LISTEN_CONFIG};
    server_name _;
    keepalive_timeout 5;

    root "#{process.env.STATIC_ROOT}";

    #{SSL_CONFIG_BLOCK}

    # this proxies the request to our node server
    location @node {
      error_page 502 = @delayed_retry;
      #{SSL_LOCATION_BLOCK}
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header  Host $http_host;
      proxy_redirect  off;
      proxy_pass  http://app_server;
    }

    # this recursively retries the same proxy as @node; the config is duplicated here because nginx will only perform
    # 10 internal redirects before returning a 500 error, so we don't want to e.g. bounce back and forth between
    # @node and @delayed_retry
    location @delayed_retry {
      error_page 502 = @delayed_retry;
      delay #{process.env.NGINX_STARTUP_RETRY_TIME}s;
      #{SSL_LOCATION_BLOCK}
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header  Host $http_host;
      proxy_redirect  off;
      proxy_pass  http://app_server;
    }

    # any calls to a /api/* path are proxied via @node
    location ^~ /api/ {
      try_files this_file_doesnt_exist @node;
      break;
    }

    # directly handle all filename resources (basically paths with <something>.<something> at the end) -- except if
    # we can't find the file, proxy to @node just in case the server is still booting
    location ~ \w+\.\w+$ {

      gzip_static on; # to serve pre-gzipped version
      expires           max;

      add_header        Cache-Control "public";
      add_header        Last-Modified "";

      try_files $uri @node;
      break;
    }

    # this is basically a wildcard location that matches anything not matched by one of the other rules, and just
    # proxies to node so it can inject the newrelic beacon into the html...  if we decide not to use newrelic for
    # in-browser metrics, then we can speed things up by having nginx serve static html (2 pages, map and admin)
    location / {
      try_files this_file_doesnt_exist @node;
      break;
    }
  }
}
"""
