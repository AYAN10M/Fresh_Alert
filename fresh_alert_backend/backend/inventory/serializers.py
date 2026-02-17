# inventory/serializers.py

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Product, UserInventory, Notification, Category


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model"""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    
    password = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password_confirm', 'first_name', 'last_name']

    def validate(self, attrs):
        """Validate that passwords match"""
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                "password": "Password fields didn't match."
            })
        return attrs

    def create(self, validated_data):
        """Create user with hashed password"""
        validated_data.pop('password_confirm')
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model"""
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'icon', 'color', 'created_at']
        read_only_fields = ['id', 'created_at']


class ProductSerializer(serializers.ModelSerializer):
    """Serializer for Product model"""
    
    class Meta:
        model = Product
        fields = [
            'id', 'qr_code', 'name', 'brand', 'category',
            'description', 'image_url', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserInventorySerializer(serializers.ModelSerializer):
    """
    Serializer for UserInventory model.
    Includes nested product information and computed fields.
    """
    
    # Nested product information (read-only)
    product = ProductSerializer(read_only=True)
    
    # Write-only field for creating inventory with product ID
    product_id = serializers.IntegerField(write_only=True, required=False)
    
    # Computed fields (read-only)
    days_until_expiry = serializers.IntegerField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    is_expiring_soon = serializers.BooleanField(read_only=True)

    class Meta:
        model = UserInventory
        fields = [
            'id', 'product', 'product_id', 'quantity',
            'purchase_date', 'expiry_date', 'location', 'notes',
            'status', 'notified', 'days_until_expiry',
            'is_expired', 'is_expiring_soon',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'status', 'created_at', 'updated_at']

    def create(self, validated_data):
        """Automatically set user from request context"""
        user = self.context['request'].user
        validated_data['user'] = user
        return super().create(validated_data)


class ScanQRSerializer(serializers.Serializer):
    """
    Serializer for scanning QR codes and adding items to inventory.
    This handles the QR scan -> create product -> add to inventory flow.
    """
    
    qr_code = serializers.CharField(max_length=255, required=True)
    expiry_date = serializers.DateField(required=True)
    quantity = serializers.IntegerField(default=1, min_value=1)
    location = serializers.CharField(max_length=100, required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True)
    
    # Optional: if product info is known from external API
    product_name = serializers.CharField(max_length=255, required=False)
    product_brand = serializers.CharField(max_length=255, required=False)
    product_category = serializers.CharField(max_length=100, required=False)

    def validate_expiry_date(self, value):
        """Ensure expiry date is not in the past"""
        from datetime import date
        if value < date.today():
            raise serializers.ValidationError("Expiry date cannot be in the past")
        return value

    def create(self, validated_data):
        """
        Create or get product, then create inventory entry.
        This is called from the view.
        """
        qr_code = validated_data['qr_code']
        user = self.context['request'].user
        
        # Get or create product
        product, created = Product.objects.get_or_create(
            qr_code=qr_code,
            defaults={
                'name': validated_data.get('product_name', f'Product {qr_code[:8]}'),
                'brand': validated_data.get('product_brand', ''),
                'category': validated_data.get('product_category', ''),
            }
        )
        
        # Create inventory entry
        inventory_item = UserInventory.objects.create(
            user=user,
            product=product,
            quantity=validated_data.get('quantity', 1),
            expiry_date=validated_data['expiry_date'],
            location=validated_data.get('location', ''),
            notes=validated_data.get('notes', ''),
        )
        
        return inventory_item


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for Notification model"""
    
    inventory_item = UserInventorySerializer(read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'notification_type', 'title', 'message',
            'inventory_item', 'is_read', 'sent_at'
        ]
        read_only_fields = ['id', 'sent_at']


class DashboardStatsSerializer(serializers.Serializer):
    """
    Serializer for dashboard statistics.
    This is not a model, just a way to structure the response.
    """
    
    total_items = serializers.IntegerField()
    expiring_soon = serializers.IntegerField()
    expired = serializers.IntegerField()
    added_today = serializers.IntegerField()
    fresh_items = serializers.IntegerField()
    
    # Optional: by category
    by_category = serializers.DictField(required=False)
    
    # Optional: by location
    by_location = serializers.DictField(required=False)


class InventoryUpdateSerializer(serializers.ModelSerializer):
    """
    Simplified serializer for updating inventory items.
    Only allows updating certain fields.
    """
    
    class Meta:
        model = UserInventory
        fields = ['quantity', 'expiry_date', 'location', 'notes', 'notified']