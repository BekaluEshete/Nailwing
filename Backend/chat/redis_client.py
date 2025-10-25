import redis
import json
from django.conf import settings


class RedisClient:
    def __init__(self):
        redis_url = settings.CHANNEL_LAYERS["default"]["CONFIG"]["hosts"][0]
        self.redis_client = redis.from_url(redis_url, decode_responses=True)

    def set_key(self, key, value, expire=None):
        """Store key-value pair in Redis"""
        if expire:
            self.redis_client.setex(key, expire, value)
        else:
            self.redis_client.set(key, value)

    def get_key(self, key):
        """Retrieve value from Redis"""
        return self.redis_client.get(key)

    def delete_key(self, key):
        """Delete key from Redis"""
        self.redis_client.delete(key)

    def add_to_list(self, list_key, value):
        """Add value to a Redis list"""
        self.redis_client.lpush(list_key, json.dumps(value))

    def get_list(self, list_key, start=0, end=-1):
        """Get values from a Redis list"""
        data = self.redis_client.lrange(list_key, start, end)
        return [json.loads(item) for item in data]

    def health_check(self):
        """Check Redis connection"""
        try:
            return self.redis_client.ping()
        except redis.ConnectionError:
            return False


# Singleton instance
redis_client = RedisClient()
