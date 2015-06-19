from locust import HttpLocust, TaskSet
import random

def index(l):
    l.client.get("/")

def login(l):
    l.client.post("/api/login", {"username": "load_test", "password": "44Jjj4W71wf4IDVbx"})

def logout(l):
    l.client.get("/api/logout")

def bounds(l):
    l.client.get("/api/properties/filter_summary/?bounds=wbl_DrrvqNt{Thl^&status%5B0%5D=for%20sale&status%5B1%5D=recently%20sold&map_position%5Bcenter%5D%5Blng%5D=-81.79364204406738&map_position%5Bcenter%5D%5Blat%5D=26.225524886426882&map_position%5Bcenter%5D%5Blon%5D=-81.8056980768368&map_position%5Bcenter%5D%5Blatitude%5D=26.264035462522518&map_position%5Bcenter%5D%5Blongitude%5D=-81.8056980768368&map_position%5Bcenter%5D%5Bzoom%5D=13&map_position%5Bcenter%5D%5BautoDiscover%5D=false&map_toggles%5BshowResults%5D=false&map_toggles%5BshowDetails%5D=false&map_toggles%5BshowFilters%5D=false&map_toggles%5BshowSearch%5D=false&map_toggles%5BisFetchingLocation%5D=false&map_toggles%5BhasPreviousLocation%5D=true&map_toggles%5BshowAddresses%5D=true&map_toggles%5BshowPrices%5D=true&map_toggles%5BshowLayerPanel%5D=false&map_results%5BselectedResultId%5D=12021_12780240000_001")

class UserBehavior(TaskSet):
    #weight the tests
    tasks = {
        login:  1,
        logout: 1,
        bounds: 5,
        index: 3
    }

    def on_start(self):
        pass

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    min_wait = 10
    max_wait = 10
