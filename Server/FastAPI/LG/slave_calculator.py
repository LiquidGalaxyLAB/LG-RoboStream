class SlaveCalculator:
    def __init__(self, total_screens: int):
        self.total_screens = total_screens
        
    @property
    def leftmost_screen(self) -> int:
        """Calculates the leftmost screen number where the logo should be displayed
        Formula: totalScreens // 2 + 2"""
        return self.total_screens // 2 + 2
    
    @property
    def rightmost_screen(self) -> int:
        """Calculates the rightmost screen number where data and camera should be displayed
        Formula: totalScreens // 2 + 1"""
        return self.total_screens // 2 + 1
    
    @property
    def master_screen(self) -> int:
        """Gets the middle screen number (master screen)"""
        return (self.total_screens // 2) + 1
    
    @property
    def is_valid_screen_count(self) -> bool:
        """Validates if the total screens number is valid"""
        return self.total_screens > 0 and self.total_screens % 2 == 1
    
    @property
    def all_screens(self) -> list:
        """Gets all screen numbers from 1 to totalScreens"""
        return list(range(1, self.total_screens + 1))
    
    def __str__(self) -> str:
        return f'SlaveCalculator(total_screens: {self.total_screens}, leftmost: {self.leftmost_screen}, rightmost: {self.rightmost_screen}, master: {self.master_screen})'
