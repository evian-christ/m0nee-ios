import SwiftUI

struct InsightsView: View {
    @State private var deleteTrigger = UUID()
    @State private var showHelpTooltip = false
    @State private var showProUpgradeModal = false
    @StateObject private var viewModel: InsightsViewModel

    init(viewModel: InsightsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.allCardTypes, id: \.rawValue) { type in
                        insightCardRow(for: type)
                    }
                }
                .padding(.vertical)
                .onAppear { viewModel.onAppear() }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .topTrailing) {
                if showHelpTooltip {
                    tooltip
                        .padding(.top, 10)
                        .padding(.trailing, 16)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showHelpTooltip)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showHelpTooltip.toggle() }) {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .sheet(isPresented: $showProUpgradeModal) {
            ProUpgradeModalView(isPresented: $showProUpgradeModal)
        }
    }

    private var tooltip: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("Long-press a card\nand select \"Add to Favourite\"\nto add it to the main screen.")
                .font(.caption)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .shadow(radius: 3)
            Button("Got it") {
                showHelpTooltip = false
            }
            .font(.caption2)
            .foregroundColor(.blue)
        }
    }

    @ViewBuilder
    private func insightCardRow(for type: InsightCardType) -> some View {
        ZStack {
            InsightCardView(
                type: type,
                expenses: viewModel.currentExpenses,
                startDate: viewModel.currentBudgetDates.start,
                endDate: viewModel.currentBudgetDates.end,
                categories: viewModel.categories,
                isProUser: viewModel.isProUser
            )
            .frame(height: 260)
            .id(type)
            .transition(.asymmetric(insertion: .identity, removal: .move(edge: .top)))
            .animation(.interpolatingSpring(stiffness: 300, damping: 20), value: deleteTrigger)
            .contextMenu {
                if viewModel.isFavourited(type) {
                    Button {
                        viewModel.toggleFavourite(type)
                    } label: {
                        Label("Remove from Favourite", systemImage: "star.slash")
                    }
                } else {
                    Button {
                        viewModel.toggleFavourite(type)
                    } label: {
                        Label("Add to Favourite", systemImage: "star")
                    }
                    .disabled(type.isProOnly && !viewModel.isProUser)
                }
                Button(role: .cancel) { } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)

            if type.isProOnly && !viewModel.isProUser {
                VStack {
                    Spacer()
                    Button(action: { showProUpgradeModal = true }) {
                        Text("Upgrade to Monir Pro")
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}
