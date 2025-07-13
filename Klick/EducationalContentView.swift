import SwiftUI

struct EducationalContentView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Rule of Thirds")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text("Place key elements of your photo where the grid lines intersect. This helps create balance and interest.")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text("Try moving your subject slightly off-center to the left or right third of the frame.")
                    .font(.body)
                    .foregroundColor(.primary)
                
                // Example image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Example Image")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
} 