
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
    server unix:#{process.env.NGINX_SOCKET_LOCATION} fail_timeout=0;
    # server unix:./nginx.socket fail_timeout=0;
  }

  server {
    listen #{process.env.PORT || 8085};
    server_name _;
    keepalive_timeout 5;

    root "#{process.env.STATIC_ROOT}";

    # this proxies the request to our node server
    location @node {
      error_page 502 = @delayed_retry;
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
