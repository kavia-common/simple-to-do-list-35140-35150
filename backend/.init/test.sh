#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/simple-to-do-list-35140-35150/backend"
cd "$WS"
# create minimal django project if missing
if [ ! -f manage.py ]; then
  python - <<'PY'
import os,sys
proj='project'
os.makedirs(proj,exist_ok=True)
open('manage.py','w').write("""#!/usr/bin/env python\nimport os,sys\nif __name__=='__main__':\n    os.environ.setdefault('DJANGO_SETTINGS_MODULE','project.settings')\n    from django.core.management import execute_from_command_line\n    execute_from_command_line(sys.argv)\n""")
open(os.path.join(proj,'__init__.py'),'w').write('')
open(os.path.join(proj,'settings.py'),'w').write("""from pathlib import Path\nBASE_DIR=Path(__file__).resolve().parent.parent\nSECRET_KEY='dev-secret-key-please-change'\nDEBUG=True\nALLOWED_HOSTS=['*']\nINSTALLED_APPS=['django.contrib.contenttypes','django.contrib.staticfiles','todo']\nMIDDLEWARE=['django.middleware.common.CommonMiddleware']\nROOT_URLCONF='project.urls'\nTEMPLATES=[{'BACKEND':'django.template.backends.django.DjangoTemplates','DIRS':[],'APP_DIRS':True,'OPTIONS':{}}]\nWSGI_APPLICATION='project.wsgi.application'\nDATABASES={'default':{'ENGINE':'django.db.backends.sqlite3','NAME':BASE_DIR/'db.sqlite3'}}\nSTATIC_URL='/static/'\n""")
open(os.path.join(proj,'urls.py'),'w').write("""from django.urls import path, include\nurlpatterns=[path('', include('todo.urls'))]\n""")
open(os.path.join(proj,'wsgi.py'),'w').write("""import os\nos.environ.setdefault('DJANGO_SETTINGS_MODULE','project.settings')\nfrom django.core.wsgi import get_wsgi_application\napplication=get_wsgi_application()\n""")
PY
fi
# create todo app files
mkdir -p todo
touch todo/__init__.py
if [ ! -f todo/views.py ]; then cat > todo/views.py <<'PY'
from django.http import HttpResponse

def index(request):
    return HttpResponse('OK')
PY
fi
if [ ! -f todo/urls.py ]; then cat > todo/urls.py <<'PY'
from django.urls import path
from .views import index
urlpatterns=[path('', index, name='index')]
PY
fi
# ensure venv
if [ ! -d .venv ]; then python -m venv .venv; fi
. .venv/bin/activate
pip install --upgrade pip setuptools wheel >/dev/null
pip install "Django>=4.2,<4.3" >/dev/null
# run provided test script actions
set +u; [ -f "$WS/.env" ] && source "$WS/.env" || true; set -u
export DJANGO_SETTINGS_MODULE=project.settings
export DJANGO_DEBUG="${DJANGO_DEBUG:-True}"
export DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY:-dev-secret-key-please-change}"
mkdir -p todo/tests
touch todo/tests/__init__.py
if [ ! -f todo/tests/test_basic.py ]; then cat > todo/tests/test_basic.py <<'PY'
from django.test import Client, TestCase
class SmokeTest(TestCase):
    def test_index(self):
        c = Client()
        resp = c.get('/')
        self.assertEqual(resp.status_code, 200)
PY
fi
python manage.py migrate --noinput
python manage.py test --verbosity=1
