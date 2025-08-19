from flask_app.main import app as wsgi_app
from asgiref.wsgi import WsgiToAsgi
from mangum import Mangum

# Wrap the Flask WSGI app as ASGI, then use Mangum for Lambda/APIGW (HTTP API v2) compatibility
asgi_app = WsgiToAsgi(wsgi_app)
handler = Mangum(asgi_app)
