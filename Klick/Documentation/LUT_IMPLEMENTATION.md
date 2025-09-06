# LUT Filter Implementation

## Overview

The Klick app now uses professional-grade .cube LUT (Look-Up Table) files for photo filtering instead of basic Core Image filters. This provides much more sophisticated and cinematic color grading capabilities.

## Architecture

### LUTApplier Class
- **Purpose**: Handles parsing and applying .cube LUT files
- **Performance**: Uses caching and optimized Core Image pipeline
- **Memory Management**: Automatic cache management with configurable limits

### FilterManager Integration
- **Preloading**: Common LUTs are preloaded at app startup for instant application
- **Caching**: Both LUT data and filtered images are cached for performance
- **Fallback**: Graceful degradation if LUT files are missing or corrupted

## Filter Collection

### 🌞 The Glow Pack (7 filters)
- **Golden Hour Glow** - Bourbon 64.CUBE - Warm, golden tones
- **Sunset Vibe** - Teigen 28.CUBE - Romantic sunset colors
- **Peach Skin** - Pitaya 15.CUBE - Flattering skin tones
- **Warm Summer** - Pasadena 21.CUBE - Bright summer vibes
- **Lucky Charm** - Lucky 64.CUBE - Cheerful and bright
- **Golden Light** - Golden Light.cube - Warm tones and rich colors inspired by Kodak Gold 200
- **Gold 200** - Gold 200.cube - Warmth and nostalgia of Kodak's rich hues and subtle contrasts

### 🎬 The Cine Pack (10 filters)
- **Cinematic Teal** - Neon 770.CUBE - Hollywood teal/orange look
- **Matte Noir** - Azrael 93.CUBE - Dark, moody aesthetic
- **Retro 90s** - Reeve 38.CUBE - Vintage film look
- **Korben Classic** - Korben 214.CUBE - Timeless cinematic
- **Chemical Wash** - Chemical 168.CUBE - Industrial, edgy
- **Faded Film** - Faded 47.CUBE - Nostalgic film aesthetic
- **Portra 800** - Portra 800.cube - Classic film emulation with neutral skin tones and vibrant colors
- **Coastal Film** - Coastal Film.cube - Mimics Gold 200 film characteristics with warm natural tones
- **Elite Chrome** - Elite Chrome.cube - Iconic vibrancy of Kodak Elite Chrome 100 with stunning saturation
- **Color 400** - Color 400.cube - Inspired by Fuji Superia 400 film with rich, bright colors and natural skin tones

### 💫 The Aesthetic Pack (8 filters)
- **Clean White** - Clouseau 54.CUBE - Minimalist, clean
- **Dreamy Pastel** - Hyla 68.CUBE - Soft, dreamy tones
- **Mocha Mood** - Arabica 12.CUBE - Warm, cozy feeling
- **Vireo Soft** - Vireo 37.CUBE - Gentle, ethereal
- **Cobi Fresh** - Cobi 3.CUBE - Modern, contemporary
- **Milo Vintage** - Milo 5.CUBE - Retro with modern appeal
- **Creatives 100** - Creatives 100.cube - Beautiful cinematic look with beach vibes
- **Portrait 100** - Portrait 100.cube - Soft and beautiful film look perfect for portraits

## Technical Details

### LUT File Format
- **Format**: Adobe .cube format
- **Size**: Typically 32x32x32 color grids
- **Location**: `/Klick/Luts/` directory
- **Naming**: Descriptive names with numbers (e.g., "Bourbon 64.CUBE")

### Performance Optimizations
1. **Preloading**: Common LUTs loaded at startup
2. **Caching**: Parsed LUT data cached in memory
3. **Efficient Blending**: Optimized intensity blending using Core Image
4. **Memory Management**: Configurable cache limits and cleanup

### Error Handling
- **Graceful Fallback**: Returns original image if LUT fails to load
- **Logging**: Comprehensive error logging for debugging
- **Validation**: LUT data validation during parsing

## Usage

### Basic Filter Application
```swift
let filteredImage = FilterManager.shared.applyFilter(
    filter, 
    to: originalImage, 
    adjustments: FilterAdjustment(intensity: 0.8, brightness: 0.1, warmth: 0.0)
)
```

### Memory Management
```swift
// Clear caches when memory is low
FilterManager.shared.clearAllCaches()

// Get memory usage info
let memoryInfo = FilterManager.shared.getMemoryInfo()
```

## Benefits Over Previous System

1. **Professional Quality**: Real LUTs used in film/photography industry
2. **Better Performance**: Optimized Core Image pipeline
3. **Consistency**: Predictable color grading across different images
4. **Expandability**: Easy to add new LUTs without code changes
5. **Industry Standard**: Uses widely-supported .cube format

## Future Enhancements

- [ ] Custom LUT import functionality
- [ ] Real-time camera preview with LUTs
- [ ] LUT intensity presets (Subtle, Balanced, Strong)
- [ ] User-created LUT collections
- [ ] LUT metadata and descriptions
