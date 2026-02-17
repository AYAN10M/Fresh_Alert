# inventory/models.py

from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import date, timedelta


class Product(models.Model):
    """
    Product information from QR code or barcode.
    Stores product details that can be reused across multiple inventory entries.
    """
    qr_code = models.CharField(
        max_length=255,
        unique=True,
        db_index=True,
        help_text="QR code or barcode value"
    )
    name = models.CharField(
        max_length=255,
        help_text="Product name"
    )
    brand = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text="Product brand"
    )
    category = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="Product category (e.g., Dairy, Vegetables, Meat)"
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Product description"
    )
    image_url = models.URLField(
        blank=True,
        null=True,
        help_text="Product image URL"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Product'
        verbose_name_plural = 'Products'

    def __str__(self):
        return f"{self.name} ({self.qr_code})"


class UserInventory(models.Model):
    """
    User's inventory items.
    Tracks individual items with their expiry dates and status.
    """
    
    STATUS_CHOICES = [
        ('fresh', 'Fresh'),
        ('expiring_soon', 'Expiring Soon'),
        ('expired', 'Expired'),
    ]
    
    # Relationships
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='inventory_items',
        help_text="User who owns this item"
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='inventory_entries',
        help_text="Product reference"
    )
    
    # Item details
    quantity = models.PositiveIntegerField(
        default=1,
        help_text="Number of items"
    )
    purchase_date = models.DateField(
        default=timezone.now,
        help_text="Date when item was purchased"
    )
    expiry_date = models.DateField(
        help_text="Expiry date of the item"
    )
    
    # Optional fields
    location = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="Storage location (e.g., Fridge, Pantry, Freezer)"
    )
    notes = models.TextField(
        blank=True,
        null=True,
        help_text="Additional notes about the item"
    )
    
    # Status tracking
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='fresh',
        help_text="Current status based on expiry date"
    )
    notified = models.BooleanField(
        default=False,
        help_text="Whether user has been notified about expiry"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['expiry_date']
        verbose_name = 'User Inventory'
        verbose_name_plural = 'User Inventories'
        indexes = [
            models.Index(fields=['user', 'expiry_date']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        return f"{self.user.username} - {self.product.name} (Expires: {self.expiry_date})"

    @property
    def days_until_expiry(self):
        """Calculate days until expiry (negative if expired)"""
        delta = self.expiry_date - date.today()
        return delta.days

    @property
    def is_expired(self):
        """Check if item is expired"""
        return self.expiry_date < date.today()

    @property
    def is_expiring_soon(self):
        """Check if item expires within 3 days"""
        return 0 <= self.days_until_expiry <= 3

    def update_status(self):
        """
        Automatically update status based on days until expiry.
        Call this before saving or in a cron job.
        """
        days = self.days_until_expiry
        
        if days < 0:
            self.status = 'expired'
        elif days <= 3:
            self.status = 'expiring_soon'
        else:
            self.status = 'fresh'
        
        return self.status

    def save(self, *args, **kwargs):
        """Override save to automatically update status"""
        self.update_status()
        super().save(*args, **kwargs)


class Notification(models.Model):
    """
    Notifications for users about expiring items.
    Optional: For future push notification feature.
    """
    
    NOTIFICATION_TYPES = [
        ('expiring_soon', 'Expiring Soon'),
        ('expired', 'Expired'),
        ('low_stock', 'Low Stock'),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    inventory_item = models.ForeignKey(
        UserInventory,
        on_delete=models.CASCADE,
        related_name='notifications',
        blank=True,
        null=True
    )
    
    notification_type = models.CharField(
        max_length=20,
        choices=NOTIFICATION_TYPES
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    
    is_read = models.BooleanField(default=False)
    sent_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-sent_at']
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'

    def __str__(self):
        return f"{self.user.username} - {self.title}"


# Optional: Category model for better organization
class Category(models.Model):
    """
    Product categories for better organization.
    Optional: Can be added later for filtering/grouping.
    """
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    icon = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text="Icon name for Flutter app"
    )
    color = models.CharField(
        max_length=7,
        default="#000000",
        help_text="Hex color code for category"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        verbose_name = 'Category'
        verbose_name_plural = 'Categories'

    def __str__(self):
        return self.name