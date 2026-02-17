from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ProductViewSet,
    UserInventoryViewSet,
    NotificationViewSet,
    CategoryViewSet,
    register_user,
    login_user,
    logout_user,
    get_current_user,
)

router = DefaultRouter()
router.register(r'products', ProductViewSet, basename='product')
router.register(r'inventory', UserInventoryViewSet, basename='inventory')
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'categories', CategoryViewSet, basename='category')

urlpatterns = [
    path('', include(router.urls)),

    # Auth endpoints
    path('auth/register/', register_user),
    path('auth/login/', login_user),
    path('auth/logout/', logout_user),
    path('auth/me/', get_current_user),
]
