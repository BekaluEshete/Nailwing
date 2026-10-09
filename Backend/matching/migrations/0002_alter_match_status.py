# Generated manually to align Match.status choices between Django versions.
# Adds 'connection_requested' to STATUS_CHOICES which was present in the model
# but missing from the initial migration.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('matching', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='match',
            name='status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending'),
                    ('viewed', 'Viewed'),
                    ('connection_requested', 'Connection Requested'),
                    ('liked', 'Liked'),
                    ('matched', 'Matched'),
                    ('rejected', 'Rejected'),
                    ('expired', 'Expired'),
                ],
                default='pending',
                max_length=20,
            ),
        ),
    ]
