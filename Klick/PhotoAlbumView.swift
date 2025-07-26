import SwiftUI

struct PhotoAlbumView: View {
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    @Binding var isFullScreen: Bool
    let onTap: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section with "Slide to view" text or close button
                VStack {
                    if isFullScreen {
                        HStack {
                            Button(action: onTap) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Close")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.black)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.black.opacity(0.15))
                            .clipShape(Capsule())
                            
                            Spacer()
                        }
                        .padding(.top, 60) // Account for safe area
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else {
                        Text("Tap to view")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
                
                // Photo grid section
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<12, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray)
                                .aspectRatio(9.0/16.0, contentMode: .fit)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Extra padding for bottom safe area
                }
            }
        }
        .background(Color.yellow)
        .clipShape(
            RoundedCorners(topLeading: 50, topTrailing: 50, bottomLeading: 0, bottomTrailing: 0)
        )
        .onTapGesture {
            if !isFullScreen {
                onTap()
            }
        }
    }
}

// Custom shape for rounded top corners only
struct RoundedCorners: Shape {
    let topLeading: CGFloat
    let topTrailing: CGFloat
    let bottomLeading: CGFloat
    let bottomTrailing: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // Start from top-leading corner
        path.move(to: CGPoint(x: topLeading, y: 0))
        
        // Top edge with top-trailing corner
        path.addLine(to: CGPoint(x: width - topTrailing, y: 0))
        path.addQuadCurve(to: CGPoint(x: width, y: topTrailing), control: CGPoint(x: width, y: 0))
        
        // Right edge with bottom-trailing corner
        path.addLine(to: CGPoint(x: width, y: height - bottomTrailing))
        path.addQuadCurve(to: CGPoint(x: width - bottomTrailing, y: height), control: CGPoint(x: width, y: height))
        
        // Bottom edge with bottom-leading corner
        path.addLine(to: CGPoint(x: bottomLeading, y: height))
        path.addQuadCurve(to: CGPoint(x: 0, y: height - bottomLeading), control: CGPoint(x: 0, y: height))
        
        // Left edge with top-leading corner
        path.addLine(to: CGPoint(x: 0, y: topLeading))
        path.addQuadCurve(to: CGPoint(x: topLeading, y: 0), control: CGPoint(x: 0, y: 0))
        
        return path
    }
}

#Preview {
    PhotoAlbumView(isFullScreen: .constant(false), onTap: {})
} 
