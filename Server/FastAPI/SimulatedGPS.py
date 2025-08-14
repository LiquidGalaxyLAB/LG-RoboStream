class LocationData:

    CURRENT_LOCATION = "Lleida"  
    IS_SIMULATION = True  

    LLEIDA_DATA = {
        "robot_gps_positions": [
            (41.606269, 0.607061), 
            (41.605460, 0.606053),  
            (41.605143, 0.606491),  
            (41.605932, 0.607541),  
            (41.606269, 0.607061)   
        ],
        
        "robot_base": {
            "latitude": 41.6175,
            "longitude": 0.6200
        },
        
        "default_orbit": {
            "latitude": 41.605725,
            "longitude": 0.606787,
            "altitude": 197.0
        },

        "default_flyto": {
            "latitude": 41.606515,
            "longitude": 0.607994,
            "elevation": 226.0573119713049,
            "tilt": 35,
            "bearing": 225,
            "altitude": 197
        },
        
        "simulation_zone": {
            "lat": 41.6176,
            "lng": 0.6200
        }
    }

    POZUELO_DATA = {
        "robot_gps_positions": [
            (40.442175, -3.832314),  
            (40.442366, -3.832003),  
            (40.442792, -3.832436),  
            (40.442649, -3.832721),  
            (40.442175, -3.832314)  
        ],
        
        "robot_base": {
            "latitude": 40.4424,
            "longitude": -3.8324
        },

        "default_orbit": {
            "latitude": 40.4424,
            "longitude": -3.8324,
            "altitude": 100  
        },
        
        "default_flyto": {
            "latitude": 40.442956,   
            "longitude": -3.831798,
            "elevation": 200, 
            "tilt": 35,
            "bearing": 225,
            "altitude": 100
        },
        
        "simulation_zone": {
            "lat": 40.4378,
            "lng": -3.8040
        }
    }

    ORBIT_PARAMETERS = {
        "slow": {
            "steps": 72,
            "step_ms": 800,
            "zoom": 197,
            "tilt": 45
        },
        "normal": {
            "steps": 36,
            "step_ms": 500,
            "zoom": 197,
            "tilt": 60
        },
        "fast": {
            "steps": 24,
            "step_ms": 200,
            "zoom": 197,
            "tilt": 75
        }
    }

    ALTITUDE_MIN = 150.0
    ALTITUDE_MAX = 200.0
    DEFAULT_ALTITUDE = 175.0

    @classmethod
    def get_current_location_data(cls):
        if cls.CURRENT_LOCATION == "Pozuelo":
            return cls.POZUELO_DATA
        else:
            return cls.LLEIDA_DATA
    
    @classmethod
    def set_current_location(cls, location_name):
        if location_name in ["Lleida", "Pozuelo"]:
            cls.CURRENT_LOCATION = location_name
            return True
        return False
    
    @classmethod
    def get_available_locations(cls):
        return ["Lleida", "Pozuelo"]
    
    @classmethod
    def get_robot_gps_sequence(cls):
        return cls.get_current_location_data()["robot_gps_positions"].copy()
    
    @classmethod
    def get_robot_initial_position(cls):
        return cls.get_current_location_data()["robot_gps_positions"][0]
    
    @classmethod
    def get_robot_base_coordinates(cls):
        return cls.get_current_location_data()["robot_base"].copy()
    
    @classmethod
    def get_default_orbit_coordinates(cls):
        return cls.get_current_location_data()["default_orbit"].copy()
    
    @classmethod
    def get_default_flyto_coordinates(cls):
        return cls.get_current_location_data()["default_flyto"].copy()
    
    @classmethod
    def get_gps_simulation_zones(cls):
        return {
            'Lleida': cls.LLEIDA_DATA["simulation_zone"],
            'Pozuelo': cls.POZUELO_DATA["simulation_zone"]
        }
    
    @classmethod
    def get_orbit_parameters(cls, orbit_type="normal"):
        return cls.ORBIT_PARAMETERS.get(orbit_type, cls.ORBIT_PARAMETERS["normal"])
    
    @classmethod
    def get_location_data(cls, location_name):
        if location_name == "Pozuelo":
            return cls.POZUELO_DATA
        elif location_name == "Lleida":
            return cls.LLEIDA_DATA
        else:
            return cls.LLEIDA_DATA  
    
    @classmethod
    def get_location_info(cls):
        return {
            "current_location": cls.CURRENT_LOCATION,
            "is_simulation": cls.IS_SIMULATION,
            "available_locations": cls.get_available_locations(),
            "location_data": cls.get_current_location_data()
        }
    
    @classmethod
    def get_gps_status_info(cls):
        return {
            "is_simulation": cls.IS_SIMULATION,
            "simulation_zone": cls.CURRENT_LOCATION if cls.IS_SIMULATION else None,
            "status": "Simulated" if cls.IS_SIMULATION else "Real",
            "location": cls.CURRENT_LOCATION
        }
    
    @classmethod
    def set_simulation_mode(cls, is_simulation):
        cls.IS_SIMULATION = is_simulation
        return True
    
    @classmethod
    def is_simulation_active(cls):
        return cls.IS_SIMULATION
