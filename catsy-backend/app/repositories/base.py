
from abc import ABC, abstractmethod
from typing import List, Optional, Any

class IReadRepository(ABC):
    @abstractmethod
    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        pass

    @abstractmethod
    def get_by_id(self, id: str) -> Optional[Any]:
        pass

class IWriteRepository(ABC):
    @abstractmethod
    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        pass

    @abstractmethod
    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        pass

class IDeletable(ABC):
    @abstractmethod
    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        pass

# Full CRUD convenience composite — use for standard domain repos
class IRepository(IReadRepository, IWriteRepository, IDeletable):
    pass
