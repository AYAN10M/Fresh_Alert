from django.contrib import admin
from .models import Product, UserInventory, Notification, Category

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'qr_code', 'brand', 'category', 'created_at')
    search_fields = ('name', 'qr_code', 'brand')
    list_filter = ('category',)

@admin.register(UserInventory)
class UserInventoryAdmin(admin.ModelAdmin):
    list_display = ('user', 'product', 'quantity', 'expiry_date', 'status')
    list_filter = ('status', 'expiry_date')
    search_fields = ('product__name', 'user__username')

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'notification_type', 'is_read', 'sent_at')
    list_filter = ('notification_type', 'is_read')

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'color', 'created_at')
    