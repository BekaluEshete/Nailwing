import redis
import json
import logging
import os

logger = logging.getLogger("chat")


class RedisClient:
    def __init__(self):
        try:
            redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
            self.redis_client = redis.from_url(redis_url, decode_responses=True)
            self.redis_client.ping()
            self.available = True
            logger.info("Redis client connected for message caching")
        except Exception as exc:
            logger.warning("Redis connection failed: %s — chat caching will be limited", exc)
            self.redis_client = None
            self.available = False

    def set_key(self, key, value, expire=None):
        if not self.available or not self.redis_client:
            return False
        try:
            if expire:
                self.redis_client.setex(key, expire, value)
            else:
                self.redis_client.set(key, value)
            return True
        except Exception:
            return False

    def get_key(self, key):
        if not self.available or not self.redis_client:
            return None
        try:
            return self.redis_client.get(key)
        except Exception:
            return None

    def delete_key(self, key):
        if not self.available or not self.redis_client:
            return False
        try:
            self.redis_client.delete(key)
            return True
        except Exception:
            return False

    def add_to_list(self, list_key, value):
        if not self.available or not self.redis_client:
            return False
        try:
            self.redis_client.lpush(list_key, json.dumps(value))
            return True
        except Exception:
            return False

    def get_list(self, list_key, start=0, end=-1):
        if not self.available or not self.redis_client:
            return []
        try:
            data = self.redis_client.lrange(list_key, start, end)
            return [json.loads(item) for item in data]
        except Exception:
            return []

    def health_check(self):
        if not self.available or not self.redis_client:
            return False
        try:
            return self.redis_client.ping()
        except redis.ConnectionError:
            return False


# Singleton instance
redis_client = RedisClient()
