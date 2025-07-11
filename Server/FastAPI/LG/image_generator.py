from PIL import Image, ImageDraw, ImageFont
import io
import math
from typing import Dict, Any, Optional

class ImageGenerator:
    def __init__(self):
        # Colors matching your app's style
        self.primary_color = (99, 102, 241)     # #6366F1
        self.secondary_color = (139, 92, 246)   # #8B5CF6  
        self.accent_color = (6, 182, 212)       # #06B6D4
        self.success_color = (16, 185, 129)     # #10B981
        self.warning_color = (245, 158, 11)     # #F59E0B
        self.surface_color = (255, 255, 255)    # White
        self.text_primary = (15, 23, 42)        # #0F172A
        self.text_secondary = (100, 116, 139)   # #64748B
        self.background = (248, 250, 252)       # #F8FAFC
        
    async def generate_sensor_image(self, sensor_info: Dict[str, Any]) -> Optional[bytes]:
        """Generates a comprehensive dashboard showing ALL sensor data"""
        try:
            # Get all sensor data first to calculate needed space
            data_list = sensor_info.get('data', [])
            
            # Calculate dynamic height based on amount of data + category headers
            base_height = 200  # Header + footer space
            item_height = 35   # Height per sensor item
            category_height = 40  # Height per category header
            spacing_height = 10   # Space between categories
            min_height = 400
            
            # Count categories that will have headers
            organized_data_preview = self._organize_sensor_data(data_list)
            num_categories = len([cat for cat, sensors in organized_data_preview.items() if sensors and cat != "Other"])
            
            # Calculate total needed height
            total_items = len(data_list)
            total_category_headers = num_categories * category_height
            total_spacing = num_categories * spacing_height
            calculated_height = base_height + (total_items * item_height) + total_category_headers + total_spacing
            
            height = max(min_height, calculated_height)
            
            # Fixed width - same as before (600px max)
            width = 600
            
            # Create image with solid background
            img = Image.new('RGB', (width, height), self.background)
            draw = ImageDraw.Draw(img)
            
            # Load fonts with fallbacks
            try:
                title_font = ImageFont.truetype("arial.ttf", 28)
                subtitle_font = ImageFont.truetype("arial.ttf", 20)
                body_font = ImageFont.truetype("arial.ttf", 16)
                small_font = ImageFont.truetype("arial.ttf", 14)
            except:
                title_font = ImageFont.load_default()
                subtitle_font = ImageFont.load_default()
                body_font = ImageFont.load_default()
                small_font = ImageFont.load_default()
            
            # Draw comprehensive dashboard
            self._draw_comprehensive_dashboard(draw, width, height, data_list, title_font, subtitle_font, body_font, small_font)
            
            # Convert to bytes
            img_byte_arr = io.BytesIO()
            img.save(img_byte_arr, format='PNG')
            return img_byte_arr.getvalue()
            
        except Exception as e:
            print(f"Error generating sensor image: {e}")
            print(f"Data list length: {len(data_list)}")
            print(f"Image dimensions: {width}x{height}")
            
            # Create a simple fallback image
            try:
                simple_img = Image.new('RGB', (600, 400), self.background)
                simple_draw = ImageDraw.Draw(simple_img)
                simple_draw.text((50, 50), "Error generating dashboard", fill=self.text_primary)
                simple_draw.text((50, 80), f"Sensors detected: {len(data_list)}", fill=self.text_secondary)
                
                fallback_byte_arr = io.BytesIO()
                simple_img.save(fallback_byte_arr, format='PNG')
                return fallback_byte_arr.getvalue()
            except:
                return None
    
    def _draw_comprehensive_dashboard(self, draw, width, height, data_list, title_font, subtitle_font, body_font, small_font):
        """Draws a comprehensive dashboard showing ALL sensor data organized efficiently"""
        margin = 20
        
        # Main background
        draw.rectangle([0, 0, width, height], fill=self.background)
        
        # Header section
        header_height = 80
        draw.rectangle([margin, margin, width - margin, margin + header_height], 
                      fill=self.primary_color, outline=self.primary_color)
        
        # Title and subtitle
        draw.text((margin + 20, margin + 15), "RoboStream Sensor Dashboard", 
                 fill=self.surface_color, font=title_font)
        draw.text((margin + 20, margin + 45), f"Real-time Data • {len(data_list)} Sensors Active", 
                 fill=self.surface_color, font=small_font)
        
        # Status indicator
        status_x = width - margin - 100
        draw.rectangle([status_x, margin + 20, status_x + 80, margin + 40], 
                      fill=self.success_color)
        draw.text((status_x + 15, margin + 25), "● LIVE", fill=self.surface_color, font=small_font)
        
        # Data area
        data_start_y = margin + header_height + 20
        
        # Organize data into categories
        organized_data = self._organize_sensor_data(data_list)
        
        current_y = data_start_y
        
        for category, sensors in organized_data.items():
            if not sensors:
                continue
                
            # Category header
            if category != "Other":
                draw.rectangle([margin + 10, current_y, width - margin - 10, current_y + 30], 
                              fill=self.accent_color, outline=self.accent_color)
                draw.text((margin + 20, current_y + 8), category, fill=self.surface_color, font=subtitle_font)
                current_y += 40
            
            # Draw sensors in this category
            for sensor in sensors:
                self._draw_sensor_item(draw, margin + 20, current_y, width - 80, 
                                     sensor, body_font, small_font)
                current_y += 35
            
            current_y += 10  # Space between categories
        
        # Footer
        footer_y = height - 50
        draw.rectangle([margin, footer_y, width - margin, height - margin], 
                      fill=(*self.text_primary, 30))
        
        # Footer content
        import time
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        draw.text((margin + 20, footer_y + 15), f"Last Updated: {timestamp}", 
                 fill=self.text_primary, font=small_font)
        
        total_sensors = len(data_list)
        draw.text((width - margin - 150, footer_y + 15), f"Total: {total_sensors} sensors", 
                 fill=self.text_primary, font=small_font)
    
    def _organize_sensor_data(self, data_list):
        """Organizes sensor data into logical categories"""
        categories = {
            "Location & Navigation": [],
            "Environmental": [],
            "Motion & Orientation": [],
            "System Status": [],
            "Other": []
        }
        
        for item in data_list:
            label = item.get('label', '').lower()
            
            if any(keyword in label for keyword in ['gps', 'position', 'latitude', 'longitude', 'location', 'speed', 'velocity', 'altitude']):
                categories["Location & Navigation"].append(item)
            elif any(keyword in label for keyword in ['temperature', 'humidity', 'pressure', 'light', 'sound']):
                categories["Environmental"].append(item)
            elif any(keyword in label for keyword in ['gyro', 'accel', 'magnet', 'rotation', 'orientation', 'imu', 'compass', 'magnetic']):
                categories["Motion & Orientation"].append(item)
            elif any(keyword in label for keyword in ['battery', 'cpu', 'memory', 'disk', 'network', 'status']):
                categories["System Status"].append(item)
            else:
                categories["Other"].append(item)
        
        # Remove empty categories
        return {k: v for k, v in categories.items() if v}
    
    def _draw_sensor_item(self, draw, x, y, width, sensor_data, body_font, small_font):
        """Draws a single sensor item with all its information"""
        # Validate inputs
        if width <= 0 or x < 0 or y < 0:
            return
            
        # Background with safe coordinates
        try:
            draw.rectangle([x, y, x + width, y + 30], 
                          fill=self.surface_color, outline=(*self.text_secondary, 100))
        except Exception as e:
            print(f"Error drawing sensor background: {e}")
            return
        
        label = sensor_data.get('label', 'Unknown Sensor')
        value = sensor_data.get('value', 'N/A')
        
        # Handle different types of values with error handling
        try:
            if isinstance(value, dict):
                # For complex values - show the EXACT values as they come
                value_str = self._format_exact_value(value)
            elif isinstance(value, (list, tuple)):
                # For array values - show exact values
                value_str = f"[{', '.join(str(v) for v in value)}]"
            else:
                # Simple values - show exact value
                value_str = str(value)
        except Exception as e:
            print(f"Error formatting value for {label}: {e}")
            value_str = f"Raw: {value}"  # Show raw value if formatting fails
        
        # Truncate very long values to prevent overflow
        max_value_length = 80
        if len(value_str) > max_value_length:
            value_str = value_str[:max_value_length-3] + "..."
        
        try:
            # Draw label
            draw.text((x + 15, y + 8), f"{label}:", fill=self.text_primary, font=body_font)
            
            # Draw value (right-aligned) with bounds checking
            value_bbox = draw.textbbox((0, 0), value_str, font=body_font)
            value_width = value_bbox[2] - value_bbox[0]
            
            # Ensure value fits within the available space
            max_value_x = x + width - 15
            value_x = max(x + 200, max_value_x - value_width)  # Ensure minimum space for label
            
            # Choose color based on value type
            if 'error' in value_str.lower() or 'fail' in value_str.lower():
                value_color = (239, 68, 68)  # Red
            elif 'ok' in value_str.lower() or 'active' in value_str.lower():
                value_color = self.success_color
            else:
                value_color = self.accent_color
                
            draw.text((value_x, y + 8), value_str, fill=value_color, font=body_font)
            
            # Status dot with bounds checking
            dot_x = x + width - 8
            dot_y = y + 6
            if dot_x > x and dot_y > y:
                draw.ellipse([dot_x, dot_y, dot_x + 4, dot_y + 4], fill=value_color)
                
        except Exception as e:
            print(f"Error drawing sensor text for {label}: {e}")
            # Fallback: draw at least the label
            try:
                draw.text((x + 15, y + 8), f"{label}: [Error]", fill=self.text_primary, font=body_font)
            except:
                pass
    
    def _format_exact_value(self, value_dict):
        """Formats complex dictionary values showing EXACT values as they come from the server"""
        if not isinstance(value_dict, dict):
            return str(value_dict)
        
        # Show ALL values exactly as they come, without any modification
        items = []
        for k, v in value_dict.items():
            # Don't modify the values, just convert to string representation
            items.append(f"{k}:{v}")
        
        return " | ".join(items)
    
    def _format_complex_value(self, value_dict):
        """Formats complex dictionary values into readable strings (DEPRECATED - keeping for compatibility)"""
        # This function is now deprecated, use _format_exact_value instead
        return self._format_exact_value(value_dict)
    
    def _draw_animated_background(self, draw, width, height):
        """Creates an animated gradient background with geometric patterns"""
        # Radial gradient background
        center_x, center_y = width // 2, height // 2
        max_radius = math.sqrt(center_x**2 + center_y**2)
        
        for radius in range(0, int(max_radius), 5):
            intensity = 1 - (radius / max_radius)
            r = int(self.background[0] + (self.primary_color[0] - self.background[0]) * intensity * 0.1)
            g = int(self.background[1] + (self.primary_color[1] - self.background[1]) * intensity * 0.1)
            b = int(self.background[2] + (self.primary_color[2] - self.background[2]) * intensity * 0.1)
            color = (r, g, b)
            
            draw.ellipse([center_x - radius, center_y - radius, 
                         center_x + radius, center_y + radius], 
                        outline=color, width=1)
        
        # Add some geometric accent shapes
        self._draw_accent_shapes(draw, width, height)
    
    def _draw_accent_shapes(self, draw, width, height):
        """Draws decorative geometric shapes"""
        # Top-right accent circle
        circle_color = (*self.accent_color, 30)
        draw.ellipse([width-150, -50, width+50, 150], fill=circle_color)
        
        # Bottom-left accent triangle
        triangle_points = [(0, height), (150, height), (0, height-150)]
        triangle_color = (*self.secondary_color, 20)
        draw.polygon(triangle_points, fill=triangle_color)
    
    def _draw_dashboard_container(self, draw, x, y, width, height):
        """Draws the main dashboard container with glass effect"""
        # Main container with shadow
        shadow_offset = 8
        shadow_color = (0, 0, 0, 20)
        self._draw_rounded_rect(draw, x+shadow_offset, y+shadow_offset, width, height, 20, shadow_color)
        
        # Main container
        self._draw_rounded_rect(draw, x, y, width, height, 20, self.surface_color)
        
        # Glass effect border
        border_color = (*self.primary_color, 100)
        self._draw_rounded_border(draw, x, y, width, height, 20, border_color, 2)
    
    def _draw_dashboard_header(self, draw, x, y, width, height, title_font, subtitle_font):
        """Draws the dashboard header with branding"""
        # Header background with gradient
        for i in range(height):
            intensity = 1 - (i / height)
            r = int(self.surface_color[0] + (self.primary_color[0] - self.surface_color[0]) * intensity * 0.05)
            g = int(self.surface_color[1] + (self.primary_color[1] - self.surface_color[1]) * intensity * 0.05)
            b = int(self.surface_color[2] + (self.primary_color[2] - self.surface_color[2]) * intensity * 0.05)
            draw.line([(x, y+i), (x+width, y+i)], fill=(r, g, b))
        
        # RoboStream logo area (left side)
        logo_size = height - 20
        self._draw_rounded_rect(draw, x+10, y+10, logo_size, logo_size, 12, self.primary_color)
        
        # "R" letter in logo
        letter_x = x + 10 + logo_size//2 - 8
        letter_y = y + 10 + logo_size//2 - 12
        draw.text((letter_x, letter_y), "R", fill=self.surface_color, font=title_font)
        
        # Title and subtitle
        title_x = x + logo_size + 30
        draw.text((title_x, y+15), "RoboStream Dashboard", fill=self.text_primary, font=title_font)
        draw.text((title_x, y+50), "Real-time Sensor Monitoring", fill=self.text_secondary, font=subtitle_font)
        
        # Status indicator (right side)
        status_x = x + width - 80
        self._draw_status_indicator(draw, status_x, y+20, "LIVE")
    
    def _draw_main_metrics(self, draw, x, y, width, height, metrics, large_font, body_font):
        """Draws the main metrics cards"""
        if not metrics:
            return
            
        card_width = (width - 40) // min(3, len(metrics))
        
        for i, metric in enumerate(metrics[:3]):
            card_x = x + i * (card_width + 20)
            self._draw_metric_card(draw, card_x, y, card_width, height, metric, large_font, body_font, i)
    
    def _draw_metric_card(self, draw, x, y, width, height, metric, large_font, body_font, index):
        """Draws a single large metric card with visual elements"""
        # Card background with color accent
        colors = [self.primary_color, self.accent_color, self.success_color]
        card_color = colors[index % len(colors)]
        
        # Card shadow
        self._draw_rounded_rect(draw, x+4, y+4, width, height, 16, (0, 0, 0, 20))
        
        # Card background
        self._draw_rounded_rect(draw, x, y, width, height, 16, self.surface_color)
        
        # Colored top accent
        self._draw_rounded_rect(draw, x, y, width, 8, 16, card_color)
        
        # Metric content
        label = metric.get('label', 'Sensor')
        value = str(metric.get('value', '0'))
        
        # Large value display
        value_y = y + 40
        self._draw_centered_text(draw, value, x, value_y, width, large_font, card_color)
        
        # Label below
        label_y = y + 80
        self._draw_centered_text(draw, label, x, label_y, width, body_font, self.text_secondary)
        
        # Progress ring or visual element
        ring_center_x = x + width // 2
        ring_center_y = y + height - 40
        self._draw_progress_ring(draw, ring_center_x, ring_center_y, 25, 0.7, card_color)
    
    def _draw_metrics_grid(self, draw, x, y, width, height, metrics, body_font, small_font):
        """Draws a grid of smaller metrics"""
        if not metrics:
            return
            
        cols = min(3, len(metrics))
        rows = math.ceil(len(metrics) / cols)
        
        cell_width = (width - (cols-1) * 15) // cols
        cell_height = (height - (rows-1) * 15) // rows
        
        for i, metric in enumerate(metrics):
            col = i % cols
            row = i // cols
            
            cell_x = x + col * (cell_width + 15)
            cell_y = y + row * (cell_height + 15)
            
            self._draw_small_metric_card(draw, cell_x, cell_y, cell_width, cell_height, 
                                       metric, body_font, small_font)
    
    def _draw_small_metric_card(self, draw, x, y, width, height, metric, body_font, small_font):
        """Draws a small metric card"""
        # Card background
        self._draw_rounded_rect(draw, x, y, width, height, 12, self.surface_color)
        
        # Border
        border_color = (*self.accent_color, 50)
        self._draw_rounded_border(draw, x, y, width, height, 12, border_color, 1)
        
        # Content
        label = metric.get('label', 'Sensor')
        value = str(metric.get('value', '0'))
        
        # Label at top
        draw.text((x+15, y+10), label, fill=self.text_secondary, font=small_font)
        
        # Value at bottom
        draw.text((x+15, y+height-30), value, fill=self.text_primary, font=body_font)
        
        # Small accent dot
        dot_color = self.accent_color
        draw.ellipse([x+width-20, y+10, x+width-10, y+20], fill=dot_color)
    
    def _draw_status_bar(self, draw, x, y, width, height, small_font):
        """Draws the bottom status bar"""
        # Background
        self._draw_rounded_rect(draw, x, y, width, height, 8, (*self.text_primary, 10))
        
        # Status text
        draw.text((x+15, y+8), "● Connected to Liquid Galaxy", fill=self.success_color, font=small_font)
        
        # Timestamp (right aligned)
        import time
        timestamp = time.strftime("%H:%M:%S")
        timestamp_bbox = draw.textbbox((0, 0), timestamp, font=small_font)
        timestamp_width = timestamp_bbox[2] - timestamp_bbox[0]
        draw.text((x+width-timestamp_width-15, y+8), timestamp, fill=self.text_secondary, font=small_font)
    
    def _draw_status_indicator(self, draw, x, y, status):
        """Draws a live status indicator"""
        # Background
        self._draw_rounded_rect(draw, x, y, 60, 25, 12, self.success_color)
        
        # Pulsing effect (simplified)
        pulse_color = (*self.success_color, 100)
        self._draw_rounded_rect(draw, x-2, y-2, 64, 29, 14, pulse_color)
        
        # Text
        draw.text((x+8, y+6), status, fill=self.surface_color, font=ImageFont.load_default())
    
    def _draw_progress_ring(self, draw, center_x, center_y, radius, progress, color):
        """Draws a progress ring"""
        # Background circle
        bg_color = (*color, 50)
        draw.ellipse([center_x-radius, center_y-radius, 
                     center_x+radius, center_y+radius], 
                    outline=bg_color, width=3)
        
        # Progress arc (simplified as partial circle)
        progress_color = color
        end_angle = int(360 * progress)
        for angle in range(0, end_angle, 5):
            x = center_x + radius * math.cos(math.radians(angle))
            y = center_y + radius * math.sin(math.radians(angle))
            draw.ellipse([x-2, y-2, x+2, y+2], fill=progress_color)
    
    def _draw_centered_text(self, draw, text, x, y, width, font, color):
        """Draws centered text within a given width"""
        text_bbox = draw.textbbox((0, 0), text, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_x = x + (width - text_width) // 2
        draw.text((text_x, y), text, fill=color, font=font)
    
    def _draw_rounded_rect(self, draw, x, y, width, height, radius, color):
        """Draws a filled rounded rectangle"""
        if width <= 0 or height <= 0:
            return
            
        # Main rectangle
        draw.rectangle([x + radius, y, x + width - radius, y + height], fill=color)
        draw.rectangle([x, y + radius, x + width, y + height - radius], fill=color)
        
        # Corners
        if radius > 0:
            draw.pieslice([x, y, x + radius * 2, y + radius * 2], 180, 270, fill=color)
            draw.pieslice([x + width - radius * 2, y, x + width, y + radius * 2], 270, 360, fill=color)
            draw.pieslice([x, y + height - radius * 2, x + radius * 2, y + height], 90, 180, fill=color)
            draw.pieslice([x + width - radius * 2, y + height - radius * 2, x + width, y + height], 0, 90, fill=color)
    
    def _draw_rounded_border(self, draw, x, y, width, height, radius, color, border_width):
        """Draws a rounded border"""
        if width <= border_width * 2 or height <= border_width * 2:
            return
            
        # Simplified border
        for i in range(border_width):
            self._draw_rounded_rect(draw, x + i, y + i, width - i * 2, height - i * 2, radius, color)
