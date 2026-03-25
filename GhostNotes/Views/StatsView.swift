import SwiftUI

struct StatsView: View {
    let stats: ReadingStats
    var streak: ReadingStreak = ReadingStreak()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // R7: Reading Streak Card
                        streakCard
                        
                        // Header stats
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Saved",
                                value: "\(stats.totalSaved)",
                                icon: "bookmark.fill",
                                color: .primary
                            )
                            
                            StatCard(
                                title: "Read",
                                value: "\(stats.totalRead)",
                                icon: "checkmark.circle.fill",
                                color: .success
                            )
                            
                            StatCard(
                                title: "Archived",
                                value: "\(stats.totalArchived)",
                                icon: "archivebox.fill",
                                color: .textSecondary
                            )
                        }
                        
                        // Cull rate
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cull Rate")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            HStack(alignment: .bottom, spacing: 12) {
                                Text("\(Int(stats.cullRate * 100))%")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("of saved articles archived")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                    .padding(.bottom, 8)
                            }
                            
                            // Visual bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.surfaceElevated)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.primary)
                                        .frame(width: geometry.size.width * stats.cullRate)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(20)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Reading time
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reading Time Saved")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            HStack(alignment: .bottom, spacing: 8) {
                                Text("\(stats.totalReadingTimeMinutes)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("minutes")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                    .padding(.bottom, 8)
                            }
                            
                            Text("of article reading you've completed")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                        .padding(20)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var streakCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reading Streak")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text("Days in a row with at least one article read")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(streak.currentStreak > 0 ? Color.orange : Color.ghost)
            }
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 4) {
                    Text("\(streak.longestStreak)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Longest")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 4) {
                    Text("\(streak.totalDaysRead)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Total Days")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StatsView(stats: ReadingStats(totalSaved: 47, totalRead: 31, totalArchived: 16, totalReadingTimeMinutes: 284), streak: ReadingStreak(currentStreak: 7, longestStreak: 14, totalDaysRead: 42))
}
