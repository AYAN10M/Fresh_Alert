# inventory/views.py

from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db.models import Count, Q
from datetime import date, timedelta

from .models import Product, UserInventory, Notification, Category
from .serializers import (
    ProductSerializer,
    UserInventorySerializer,
    ScanQRSerializer,
    NotificationSerializer,
    CategorySerializer,
    DashboardStatsSerializer,
    InventoryUpdateSerializer,
    UserSerializer,
    UserRegistrationSerializer
)


# ==================== Authentication Views ====================

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """
    Register a new user.
    
    POST /api/auth/register/
    {
        "username": "john",
        "email": "john@example.com",
        "password": "password123",
        "password_confirm": "password123"
    }
    """
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        token, created = Token.objects.get_or_create(user=user)
        
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data,
            'message': 'User registered successfully'
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """
    Login user and return auth token.
    
    POST /api/auth/login/
    {
        "username": "john",
        "password": "password123"
    }
    """
    username = request.data.get('username')
    password = request.data.get('password')
    
    if not username or not password:
        return Response({
            'error': 'Please provide both username and password'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    user = authenticate(username=username, password=password)
    
    if not user:
        return Response({
            'error': 'Invalid credentials'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    token, created = Token.objects.get_or_create(user=user)
    
    return Response({
        'token': token.key,
        'user': UserSerializer(user).data
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_user(request):
    """
    Logout user by deleting their token.
    
    POST /api/auth/logout/
    Header: Authorization: Token <token>
    """
    try:
        request.user.auth_token.delete()
        return Response({
            'message': 'Successfully logged out'
        })
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_current_user(request):
    """
    Get current authenticated user info.
    
    GET /api/auth/me/
    Header: Authorization: Token <token>
    """
    return Response(UserSerializer(request.user).data)


# ==================== Product ViewSet ====================

class ProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Product model.
    Provides CRUD operations for products.
    """
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Filter products by QR code if provided"""
        queryset = Product.objects.all()
        qr_code = self.request.query_params.get('qr_code', None)
        
        if qr_code:
            queryset = queryset.filter(qr_code=qr_code)
        
        return queryset


# ==================== User Inventory ViewSet ====================

class UserInventoryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for UserInventory model.
    Provides CRUD operations and custom actions.
    """
    serializer_class = UserInventorySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Return only current user's inventory items"""
        return UserInventory.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        """Use different serializer for updates"""
        if self.action in ['update', 'partial_update']:
            return InventoryUpdateSerializer
        return UserInventorySerializer

    @action(detail=False, methods=['post'])
    def scan_qr(self, request):
        """
        Add item to inventory by scanning QR code.
        
        POST /api/inventory/scan_qr/
        {
            "qr_code": "123456789",
            "expiry_date": "2026-03-15",
            "quantity": 1,
            "location": "Fridge",
            "notes": "Bought from local store"
        }
        """
        serializer = ScanQRSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            inventory_item = serializer.save()
            
            # Return the created inventory item with full details
            return Response(
                UserInventorySerializer(inventory_item).data,
                status=status.HTTP_201_CREATED
            )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'])
    def dashboard_stats(self, request):
        """
        Get dashboard statistics for current user.
        
        GET /api/inventory/dashboard_stats/
        """
        user_inventory = self.get_queryset()
        today = date.today()
        
        # Calculate statistics
        total_items = user_inventory.count()
        
        expiring_soon = user_inventory.filter(
            expiry_date__lte=today + timedelta(days=3),
            expiry_date__gte=today
        ).count()
        
        expired = user_inventory.filter(
            expiry_date__lt=today
        ).count()
        
        added_today = user_inventory.filter(
            created_at__date=today
        ).count()
        
        fresh_items = user_inventory.filter(
            expiry_date__gt=today + timedelta(days=3)
        ).count()
        
        stats = {
            'total_items': total_items,
            'expiring_soon': expiring_soon,
            'expired': expired,
            'added_today': added_today,
            'fresh_items': fresh_items,
        }
        
        serializer = DashboardStatsSerializer(stats)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def expiring_items(self, request):
        """
        Get items expiring soon.
        
        GET /api/inventory/expiring_items/?days=7
        """
        days = int(request.query_params.get('days', 7))
        today = date.today()
        
        items = self.get_queryset().filter(
            expiry_date__lte=today + timedelta(days=days),
            expiry_date__gte=today
        ).order_by('expiry_date')
        
        serializer = self.get_serializer(items, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def expired_items(self, request):
        """
        Get expired items.
        
        GET /api/inventory/expired_items/
        """
        today = date.today()
        
        items = self.get_queryset().filter(
            expiry_date__lt=today
        ).order_by('-expiry_date')
        
        serializer = self.get_serializer(items, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_location(self, request):
        """
        Get items grouped by location.
        
        GET /api/inventory/by_location/
        """
        locations = self.get_queryset().values('location').annotate(
            count=Count('id')
        ).order_by('-count')
        
        return Response(locations)

    @action(detail=False, methods=['get'])
    def by_category(self, request):
        """
        Get items grouped by category.
        
        GET /api/inventory/by_category/
        """
        categories = self.get_queryset().values(
            'product__category'
        ).annotate(
            count=Count('id')
        ).order_by('-count')
        
        return Response(categories)

    @action(detail=True, methods=['post'])
    def mark_as_consumed(self, request, pk=None):
        """
        Mark item as consumed (delete from inventory).
        
        POST /api/inventory/{id}/mark_as_consumed/
        """
        item = self.get_object()
        item.delete()
        
        return Response({
            'message': 'Item marked as consumed'
        }, status=status.HTTP_204_NO_CONTENT)


# ==================== Notification ViewSet ====================

class NotificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Notification model.
    """
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Return only current user's notifications"""
        return Notification.objects.filter(user=self.request.user)

    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """
        Mark notification as read.
        
        POST /api/notifications/{id}/mark_as_read/
        """
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        
        return Response(self.get_serializer(notification).data)

    @action(detail=False, methods=['post'])
    def mark_all_as_read(self, request):
        """
        Mark all notifications as read.
        
        POST /api/notifications/mark_all_as_read/
        """
        self.get_queryset().update(is_read=True)
        
        return Response({
            'message': 'All notifications marked as read'
        })


# ==================== Category ViewSet ====================

class CategoryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Category model.
    """
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [IsAuthenticated]