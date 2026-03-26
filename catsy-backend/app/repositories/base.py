from abc import ABC, abstractmethod
from typing import List, Optional, Any

class IRepository(ABC):
    """
    Base abstraction for a generic Repository.
    This enforces the Dependency Inversion Principle mapping to CRUD behaviors.
    """
    
    @abstractmethod
    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        pass

    @abstractmethod
    def get_by_id(self, id: str) -> Optional[Any]:
        pass

    @abstractmethod
    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        pass

    @abstractmethod
    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        pass

    @abstractmethod
    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        pass
