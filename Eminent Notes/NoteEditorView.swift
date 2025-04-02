import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var viewModel: NoteEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FocusState private var focusField: Field?
    
    enum Field {
        case title, content
    }
    
    @State private var showingFormatting = false
    @State private var selectedTextRange: NSRange?
    @State private var showingDiscardAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title field
            TextField("Title", text: $viewModel.title)
                .font(.title)
                .padding(.horizontal)
                .padding(.top)
                .focused($focusField, equals: .title)
            
            Divider()
                .padding(.horizontal)
            
            // Formatting toolbar (visible when formatting is active)
            if showingFormatting {
                FormattingToolbar(content: $viewModel.content, selectedRange: $selectedTextRange)
                    .padding(.vertical, 8)
                
                Divider()
                    .padding(.horizontal)
            }
            
            // Content editor
            TextEditor(text: $viewModel.content)
                .font(.body)
                .padding(.horizontal)
                .focused($focusField, equals: .content)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.focusField = .content
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(viewModel.title.isEmpty ? "New Note" : viewModel.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            // Pin toggle button
            ToolbarItem(placement: toolbarPlacement()) {
                Button {
                    viewModel.togglePin()
                } label: {
                    Image(systemName: viewModel.isPinned ? "pin.fill" : "pin")
                }
            }
            
            // Formatting toggle button
            ToolbarItem(placement: toolbarPlacement()) {
                Button {
                    showingFormatting.toggle()
                } label: {
                    Image(systemName: "textformat")
                }
            }
            
            // Save button
            ToolbarItem(placement: toolbarPlacement()) {
                Button {
                    viewModel.saveNote()
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
            
            // Discard button (only shown when there are unsaved changes)
            if viewModel.hasUnsavedChanges {
                ToolbarItem(placement: leadingToolbarPlacement()) {
                    Button {
                        showingDiscardAlert = true
                    } label: {
                        Text("Discard")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                viewModel.discardChanges()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to discard your unsaved changes?")
        }
        .onChange(of: viewModel.title) { oldValue, newValue in
            if !newValue.isEmpty {
                // Update navigation title when title changes
                // (This is not needed for SwiftUI, but just to illustrate the concept)
            }
        }
    }
    
    // Helper method to determine proper toolbar placement
    private func toolbarPlacement() -> ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }
    
    // Helper method for leading toolbar placement
    private func leadingToolbarPlacement() -> ToolbarItemPlacement {
        #if os(macOS)
        return .cancellationAction
        #else
        return .navigationBarLeading
        #endif
    }
}

// Add the missing FormattingToolbar struct
struct FormattingToolbar: View {
    @Binding var content: String
    @Binding var selectedRange: NSRange?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FormatButton(icon: "bold", action: { applyFormat(format: "**", content: $content, range: selectedRange) })
                FormatButton(icon: "italic", action: { applyFormat(format: "*", content: $content, range: selectedRange) })
                Divider().frame(height: 24)
                FormatButton(icon: "list.bullet", action: { addBulletList(content: $content, range: selectedRange) })
                FormatButton(icon: "list.number", action: { addNumberedList(content: $content, range: selectedRange) })
                Divider().frame(height: 24)
                FormatButton(icon: "checkmark.square", action: { addCheckbox(content: $content, range: selectedRange) })
                FormatButton(icon: "text.append", action: { addHeader(content: $content, range: selectedRange) })
            }
            .padding(.horizontal)
        }
    }
    
    private func applyFormat(format: String, content: Binding<String>, range: NSRange?) {
        guard let range = range, range.length > 0 else { return }
        
        let nsString = NSString(string: content.wrappedValue)
        let selectedText = nsString.substring(with: range)
        
        let formattedText = "\(format)\(selectedText)\(format)"
        
        var newContent = content.wrappedValue
        newContent = (newContent as NSString).replacingCharacters(in: range, with: formattedText)
        content.wrappedValue = newContent
    }
    
    private func addBulletList(content: Binding<String>, range: NSRange?) {
        guard let range = range else { return }
        
        let nsString = NSString(string: content.wrappedValue)
        let selectedText = nsString.substring(with: range)
        
        // Split text by new line and add bullets
        let lines = selectedText.split(separator: "\n")
        let bulletedLines = lines.map { "• \($0)" }.joined(separator: "\n")
        
        var newContent = content.wrappedValue
        newContent = (newContent as NSString).replacingCharacters(in: range, with: bulletedLines)
        content.wrappedValue = newContent
    }
    
    private func addNumberedList(content: Binding<String>, range: NSRange?) {
        guard let range = range else { return }
        
        let nsString = NSString(string: content.wrappedValue)
        let selectedText = nsString.substring(with: range)
        
        // Split text by new line and add numbers
        let lines = selectedText.split(separator: "\n")
        let numberedLines = lines.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        
        var newContent = content.wrappedValue
        newContent = (newContent as NSString).replacingCharacters(in: range, with: numberedLines)
        content.wrappedValue = newContent
    }
    
    private func addCheckbox(content: Binding<String>, range: NSRange?) {
        guard let range = range else { return }
        
        let nsString = NSString(string: content.wrappedValue)
        let selectedText = nsString.substring(with: range)
        
        // Split text by new line and add checkboxes
        let lines = selectedText.split(separator: "\n")
        let checkboxLines = lines.map { "[ ] \($0)" }.joined(separator: "\n")
        
        var newContent = content.wrappedValue
        newContent = (newContent as NSString).replacingCharacters(in: range, with: checkboxLines)
        content.wrappedValue = newContent
    }
    
    private func addHeader(content: Binding<String>, range: NSRange?) {
        guard let range = range else { return }
        
        let nsString = NSString(string: content.wrappedValue)
        let selectedText = nsString.substring(with: range)
        
        let headerText = "## \(selectedText)"
        
        var newContent = content.wrappedValue
        newContent = (newContent as NSString).replacingCharacters(in: range, with: headerText)
        content.wrappedValue = newContent
    }
}

struct FormatButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 30, height: 30)
        }
    }
}

#Preview {
    NavigationView {
        NoteEditorView(viewModel: NoteEditorViewModel())
    }
}
