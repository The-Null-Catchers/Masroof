proxy_http_version 1.1;
proxy_set_header Connection "";
# $http_host keeps the port, which the BFF same-origin check compares with Origin.
proxy_set_header Host $http_host;
proxy_set_header X-Forwarded-Host $http_host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $forwarded_proto;
proxy_read_timeout 120s;
