from locust import HttpUser, task, between
import os

class MyUser(HttpUser):
    wait_time = between(1, 3)
    # enable when authentication needed
    token = os.environ['OAUTH_COOKIE']

    @task
    def post_data(self):
        # enable when authentication needed
        cookies = {
            "_oauth2_proxy": self.token
        }

        files = {
            "file": ("dinosaur.pdf", open("dinosaur.pdf", "rb"), "application/pdf"),
        }

        data = {
            "dpi": "300",
            "page": "1",
        }
        with self.client.post("/render", files=files, data=data, cookies=cookies, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with {response.status_code}:\n, {response.content}")