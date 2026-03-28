from typing import Generator
from fastapi import Request

from app.repositories.orders_repo import OrderRepository
from app.repositories.loyalty_repo import LoyaltyRepository
from app.repositories.reservations_repo import ReservationRepository
from app.repositories.products_repo import ProductRepository
from app.repositories.categories_repo import CategoryRepository
from app.repositories.users_repo import UserRepository
from app.repositories.settings_repo import SettingsRepository
from app.repositories.customer_repo import CustomerRepository
from app.repositories.auth_repo import AuthRepository

from app.services.order_service import OrderService
from app.services.loyalty_service import LoyaltyService

# Repositories
def get_order_repository() -> OrderRepository:
    return OrderRepository()

def get_loyalty_repository() -> LoyaltyRepository:
    return LoyaltyRepository()

def get_reservation_repository() -> ReservationRepository:
    return ReservationRepository()

def get_product_repository() -> ProductRepository:
    return ProductRepository()

def get_category_repository() -> CategoryRepository:
    return CategoryRepository()

def get_user_repository() -> UserRepository:
    return UserRepository()

def get_settings_repository() -> SettingsRepository:
    return SettingsRepository()

def get_customer_repository() -> CustomerRepository:
    return CustomerRepository()

def get_auth_repository() -> AuthRepository:
    return AuthRepository()

# Services
def get_order_service() -> OrderService:
    order_repo = get_order_repository()
    product_repo = get_product_repository()
    return OrderService(order_repo=order_repo, product_repo=product_repo)

def get_loyalty_service() -> LoyaltyService:
    repo = get_loyalty_repository()
    return LoyaltyService(loyalty_repo=repo)
