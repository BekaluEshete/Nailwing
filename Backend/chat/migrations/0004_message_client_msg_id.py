"""
Add client_msg_id to Message for idempotent message delivery.

The Flutter client assigns a UUID before sending each message.
On retry (network failure / offline sync), the same UUID is sent again.
The backend uses get_or_create on this field so duplicate sends never
produce duplicate messages.
"""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('chat', '0003_alter_message_message_type_readreceipt'),
    ]

    operations = [
        migrations.AddField(
            model_name='message',
            name='client_msg_id',
            field=models.UUIDField(
                blank=True,
                db_index=True,
                help_text='Client-generated UUID for idempotent message delivery.',
                null=True,
                unique=True,
            ),
        ),
    ]
