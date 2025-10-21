from django.test import Client, TestCase
class SmokeTest(TestCase):
    def test_index(self):
        c = Client()
        resp = c.get('/')
        self.assertEqual(resp.status_code, 200)
