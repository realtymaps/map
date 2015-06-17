
process.stdout.write """
daemon off;
worker_processes #{process.env['NGINX_WORKERS'] || 4};
pid /app/nginx.pid;

events {
  use epoll;
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
    server unix:/tmp/nginx.socket fail_timeout=0;
  }

  server {
    listen #{process.env["PORT"]};
    server_name _;
    keepalive_timeout 5;

    root "/app/_public";

    location @node {
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header  Host $http_host;
      proxy_redirect  off;
      proxy_pass  http://app_server;
    }

    location / {
      error_page 502 = @delayed_retry;
      gzip_static on; # to serve pre-gzipped version
      add_header        Cache-Control "public, must-revalidate";
      expires           10m;
      try_files $uri /$uri /rmap.html @node;
    }

    location ~ ^/(api|login)/ {
      try_files $uri @node;
    }

    # because we need everything else that is a non .{whatever} or non file route to hit scalatra
    # we handle all root resources (non /assets/ resource files here and route to node root)
    location ~* ^.+\.(woff|ttf|svg|htc|png){

      gzip_static on; # to serve pre-gzipped version
      expires           max;

      add_header        Cache-Control "public, must-revalidate";
      add_header        Last-Modified "";

      try_files $uri /$uri;

    }

    # this is a recursive retry location; nginx will only recurse 10 times before returning a 500 error
    location @delayed_retry {
      error_page 502 = @delayed_retry;
      delay #{process.env["STARTUP_RETRY_TIME"]}s;
      try_files uri @node;
    }
  }
}
"""
