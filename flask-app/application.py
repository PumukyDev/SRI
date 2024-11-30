from flask import Flask

# Definimos el objeto
app = Flask(__name__)

# Con el arroba, podemos hacer un 'metadato', así cuando
# alguien nos pida esta página, hará lo de abajo
@app.route('/')
def indec():
	"Index"
	return "<h1>App desplegada</h1>"
