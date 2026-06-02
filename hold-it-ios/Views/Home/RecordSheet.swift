//
//  RecordSheet.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

struct RecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedCategory: ResistCategory = ResistCategory.defaults[0]
    @State private var note: String = ""
    @State private var showSuccess = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if showSuccess {
                    successView
                } else {
                    formContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .navigationTitle("你忍住了什么？")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var formContent: some View {
        VStack(spacing: 24) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ResistCategory.defaults) { category in
                    CategoryCell(
                        category: category,
                        isSelected: selectedCategory.id == category.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("备注（可选）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("差点下单新键盘…", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            
            Spacer()
            
            Button {
                saveRecord()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("保存记录")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(16)
            }
            .padding(.bottom, 24)
        }
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolEffect(.bounce)
            
            Text("已记录")
                .font(.title2.weight(.bold))
            
            Text("你又忍住了一次 \(selectedCategory.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
    
    private func saveRecord() {
        let record = ResistRecord(
            category: selectedCategory.name,
            categoryEmoji: selectedCategory.emoji,
            note: note,
            amount: selectedCategory.defaultAmount
        )
        modelContext.insert(record)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

struct CategoryCell: View {
    let category: ResistCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(category.emoji)
                    .font(.system(size: 32))
                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
