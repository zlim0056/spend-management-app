//
//  CategoryCheckList.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 04/10/2025.
//

import SwiftUI

// A struct that represents each category and whether it is selected
struct Categories: Identifiable {
    var id = UUID()
    var category: Category
    var isSelected: Bool
}

struct CategoryCheckList: View {
    // List of all categories displayed
    @State var categories: [Categories] = []
    
    // Check if all categories are currently selected
    var allSelected: Bool {
        !categories.isEmpty && categories.allSatisfy { $0.isSelected }
    }
    
    // Delegate used to pass selected categories back
    var delegate: BudgetDetailViewControllerDelegate?
    
    // Used when editing an existing budget
    var currentBudget: Budget?
    
    var body: some View {
        VStack {
            // "Select all / Deselect all" header row
            HStack {
                Text(allSelected ? "Deselect all" : "Select all")
                Spacer()
                Image(systemName: allSelected ? "checkmark.square" : "square")
            }
            .contentShape(Rectangle()) // make the entire row tappable
            .padding(.horizontal)
            .onTapGesture {
                // Toggle between select all and deselect all
                toggleSelectAll()
                getSelectedCategories()
            }
            
            // List of all categories
            List($categories) { $category in
                HStack {
                    Text(category.category.name ?? "")
                    Spacer()
                    Image(systemName: category.isSelected ? "checkmark.square" : "square")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Toggle individual category selection
                    category.isSelected.toggle()
                    getSelectedCategories()
                }
            }
        }
        // Load categories when view first appears
        .onAppear {
            loadCategories()
        }
    }
    
    // Toggle all categories between selected and deselected
    func toggleSelectAll() {
        let newValue = !allSelected
        for index in categories.indices {
            categories[index].isSelected = newValue
        }
    }
    
    // Load all expense-type categories
    func loadCategories() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let databaseController = appDelegate?.databaseController as? CoreDataController
        
        // Fetch only categories of type "expense"
        let filtered = databaseController?.fetchAllCategories().filter { $0.financialType == .expense } ?? []
        
        // Build list with pre-selected states
        for cat in filtered {
            categories.append(Categories(category: cat, isSelected: delegate?.selectedCategories?.contains(cat) ?? false))
        }
    }
    
    // Update delegate when category selection changes
    func getSelectedCategories() {
        var categoriesList: [Category] = []
        
        // Collect all selected categories
        for cat in categories {
            if cat.isSelected {
                categoriesList.append(cat.category)
            }
        }
        
        // Send back to BudgetDetailViewController
        delegate?.selectedCategories = categoriesList
        delegate?.configureCategoryButton()
    }
}
