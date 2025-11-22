# Generated migration for Cloudinary fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('authentication', '0002_alter_customuser_options_alter_customuser_table'),
    ]

    operations = [
        migrations.AddField(
            model_name='customuser',
            name='profile_image_url',
            field=models.URLField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='customuser',
            name='cloudinary_public_id',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
    ]

