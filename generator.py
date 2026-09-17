import json, random, time, uuid
from datetime import datetime, timezone
from google.cloud import pubsub_v1

PROJECT = "telecom-stream-demo"
TOPIC = "cdr-events"
RUN_MINUTES = 90

pub = pubsub_v1.PublisherClient()
topic = pub.topic_path(PROJECT, TOPIC)
towers = [f"TWR-{i:03d}" for i in range(50)]
bad_towers = random.sample(towers, 3)
print("Bad towers this run:", bad_towers, flush=True)

end_time = time.time() + RUN_MINUTES * 60
count = 0
while time.time() < end_time:
    tower = random.choice(towers)
    weights = [65, 30, 5] if tower in bad_towers else [90, 7, 3]
    event = {
        "call_id": str(uuid.uuid4()),
        "caller": f"+1{random.randint(2000000000, 9999999999)}",
        "tower_id": tower,
        "duration_sec": random.randint(0, 1800),
        "status": random.choices(["completed", "dropped", "failed"], weights)[0],
        "signal_dbm": random.randint(-120, -50),
        "event_ts": datetime.now(timezone.utc).isoformat(),
    }
    pub.publish(topic, json.dumps(event).encode())
    count += 1
    if count % 1000 == 0:
        print("Events sent so far:", count, flush=True)
    time.sleep(0.05)

print("Done. Total events sent:", count, flush=True)
