
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
  gzip_comp_level 2;
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

    location / {
      error_page 502 = @delayed_retry;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
      proxy_pass http://app_server;
    }

    # this is a recursive retry location; nginx will only recurse 10 times before returning a 500 error
    location @delayed_retry {
      error_page 502 = @delayed_retry;
      delay #{process.env["STARTUP_RETRY_TIME"]}s;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
      proxy_pass http://app_server;
    }
  }
}
"""
