import SwiftUI

struct NewsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: NewsCategory = .all
    @State private var showNewPostSheet = false
    @State private var selectedPost: NewsPost? = nil

    private var filteredPosts: [NewsPost] {
        if selectedCategory == .all {
            return appState.newsPosts
        }
        return appState.newsPosts.filter { $0.category == selectedCategory }
    }

    var body: some View {
        HSplitView {
            // MARK: - Left: Post List
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("뉴스")
                                .font(.title.weight(.bold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("커뮤니티 소식과 토론")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        Spacer()

                        Button {
                            showNewPostSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.pencil")
                                Text("글쓰기")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.cyan.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }

                    // Category Tabs
                    HStack(spacing: 8) {
                        ForEach(NewsCategory.allCases, id: \.self) { category in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.caption)
                                    Text(category.rawValue)
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(selectedCategory == category ? .white : AppTheme.secondaryText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    selectedCategory == category
                                        ? AnyShapeStyle(category.color.gradient)
                                        : AnyShapeStyle(AppTheme.cardBackgroundLight)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedCategory == category ? Color.clear : AppTheme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }

                    // Post List
                    VStack(spacing: 10) {
                        ForEach(filteredPosts) { post in
                            NewsPostRow(post: post, isSelected: selectedPost?.id == post.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedPost = post
                                    }
                                }
                        }
                    }
                    .onChange(of: selectedCategory) { _, newCat in
                        Task {
                            await appState.fetchNews(category: newCat == .all ? nil : newCat)
                            // 선택된 게시글이 있으면 최신 데이터로 동기화
                            if let currentPost = selectedPost,
                               let updated = appState.newsPosts.first(where: { $0.id == currentPost.id }) {
                                selectedPost = updated
                            }
                        }
                    }
                    .onAppear {
                        Task {
                            await appState.fetchNews(category: selectedCategory == .all ? nil : selectedCategory)
                            // 선택된 게시글이 있으면 최신 데이터로 동기화
                            if let currentPost = selectedPost,
                               let updated = appState.newsPosts.first(where: { $0.id == currentPost.id }) {
                                selectedPost = updated
                            }
                        }
                    }

                    if filteredPosts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "newspaper")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.tertiaryText)
                            Text("아직 글이 없습니다")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("첫 번째 글을 작성해보세요!")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(24)
            }
            .frame(minWidth: 500)
            .background(AppTheme.background)

            // MARK: - Right: Post Detail
            if let post = selectedPost {
                let postToShow = appState.newsPosts.first(where: { $0.id == post.id }) ?? post
                NewsPostDetailView(post: postToShow, onUpdate: { updatedPost in
                    if let index = appState.newsPosts.firstIndex(where: { $0.id == updatedPost.id }) {
                        appState.newsPosts[index] = updatedPost
                        selectedPost = updatedPost
                    }
                }, onDelete: {
                    selectedPost = nil
                })
                .environmentObject(appState)
                .frame(width: 360)
                .background(AppTheme.background)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text("글을 선택해주세요")
                        .font(.headline)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("왼쪽에서 글을 선택하면\n상세 내용을 볼 수 있습니다")
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 360)
                .frame(maxHeight: .infinity)
                .background(AppTheme.background)
            }
        }
        .sheet(isPresented: $showNewPostSheet) {
            NewPostSheet()
                .environmentObject(appState)
        }
    }
}

// MARK: - News Post Row
struct NewsPostRow: View {
    let post: NewsPost
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top: Category badge + time
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: post.category.icon)
                        .font(.system(size: 9))
                    Text(post.category.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(post.category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(post.category.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            // Title
            Text(post.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)

            // Content preview
            Text(post.content)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)

            // Bottom: Author + stats
            HStack {
                // Author
                HStack(spacing: 6) {
                    if post.isAnonymous {
                        Image(systemName: "person.fill.questionmark")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.tertiaryText)
                    } else {
                        Circle()
                            .fill(post.avatarColor.gradient)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text(String(post.author.prefix(1)))
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                    Text(post.displayAuthor)
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                }

                Spacer()

                // Likes + Comments
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.pink.opacity(0.8))
                        Text("\(post.likes)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }

                    HStack(spacing: 3) {
                        Image(systemName: "bubble.right.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.cyan.opacity(0.8))
                        Text("\(post.comments.count)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(isSelected ? AppTheme.cardBackgroundLight : AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.cyan.opacity(0.5) : AppTheme.border, lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

// MARK: - News Post Detail View
struct NewsPostDetailView: View {
    @EnvironmentObject var appState: AppState
    let post: NewsPost
    var onUpdate: (NewsPost) -> Void
    var onDelete: () -> Void
    @State private var newComment: String = ""
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var isSubmittingComment = false

    private var isMyPost: Bool {
        guard let uid = appState.currentUser?.id else { return false }
        return post.authorId == uid
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category + Time + Edit/Delete (본인 글만)
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: post.category.icon)
                                .font(.system(size: 10))
                            Text(post.category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(post.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(post.category.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        Spacer()

                        if isMyPost {
                            Button {
                                showEditSheet = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)

                            Button {
                                showDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                        }

                        Text(post.timeAgo)
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }

                    // Title
                    Text(post.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)

                    // Author
                    HStack(spacing: 8) {
                        if post.isAnonymous {
                            Circle()
                                .fill(Color.gray.gradient)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "person.fill.questionmark")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                )
                        } else {
                            AvatarView(name: post.author, color: post.avatarColor, size: 28)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(post.displayAuthor)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.primaryText)
                            if !post.isAnonymous {
                                Text(post.authorTicker)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.tertiaryText)
                            }
                        }
                    }

                    Divider().background(AppTheme.border)

                    // Content
                    Text(post.content)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineSpacing(4)

                    // Likes
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                await appState.likeNewsPost(postId: post.id)
                                if let updated = appState.newsPosts.first(where: { $0.id == post.id }) {
                                    onUpdate(updated)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .font(.subheadline)
                                Text("\(post.likes)")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.cardBackgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .font(.subheadline)
                            Text("\(post.comments.count)")
                                .font(.subheadline)
                        }
                        .foregroundStyle(AppTheme.secondaryText)

                        Spacer()
                    }

                    Divider().background(AppTheme.border)

                    // Comments
                    VStack(alignment: .leading, spacing: 12) {
                        Text("댓글 \(post.comments.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        if post.comments.isEmpty {
                            Text("아직 댓글이 없습니다")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                                .padding(.vertical, 12)
                        } else {
                            ForEach(post.comments) { comment in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(comment.author)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppTheme.primaryText)
                                        Spacer()
                                        Text(comment.timeAgo)
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.tertiaryText)
                                    }
                                    Text(comment.content)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                .padding(10)
                                .background(AppTheme.cardBackgroundLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(20)
            }

            // Comment Input
            Divider().background(AppTheme.border)
            HStack(spacing: 8) {
                TextField("댓글을 입력하세요...", text: $newComment)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    let content = newComment.trimmingCharacters(in: .whitespaces)
                    guard !content.isEmpty, !isSubmittingComment else { return }
                    isSubmittingComment = true
                    Task {
                        if await appState.addNewsComment(postId: post.id, content: content) != nil {
                            newComment = ""
                            if let updated = appState.newsPosts.first(where: { $0.id == post.id }) {
                                onUpdate(updated)
                            }
                        }
                        isSubmittingComment = false
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
                .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty || isSubmittingComment)
            }
            .padding(12)
            .background(AppTheme.cardBackground)
        }
        .sheet(isPresented: $showEditSheet) {
            EditPostSheet(post: post) { updatedPost in
                onUpdate(updatedPost)
                showEditSheet = false
            }
            .environmentObject(appState)
        }
        .alert("글 삭제", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task {
                    if await appState.deleteNewsPost(postId: post.id) {
                        onDelete()
                    }
                }
            }
        } message: {
            Text("이 글을 삭제할까요? 삭제된 글은 복구할 수 없습니다.")
        }
    }
}

// MARK: - New Post Sheet
struct NewPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var category: NewsCategory = .free
    @State private var isAnonymous: Bool = false
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("취소") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Text("새 글 작성")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Button("게시") {
                    guard canSubmit, !isSubmitting else { return }
                    isSubmitting = true
                    Task {
                        if await appState.createNewsPost(title: title, content: content, category: category, anonymous: isAnonymous) != nil {
                            dismiss()
                        }
                        isSubmitting = false
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(canSubmit && !isSubmitting ? .cyan : AppTheme.tertiaryText)
                .disabled(!canSubmit || isSubmitting)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().background(AppTheme.border)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("카테고리")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)

                        HStack(spacing: 8) {
                            ForEach(NewsCategory.allCases.filter { $0 != .all }, id: \.self) { cat in
                                Button {
                                    category = cat
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.caption)
                                        Text(cat.rawValue)
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(category == cat ? .white : AppTheme.secondaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        category == cat
                                            ? AnyShapeStyle(cat.color.gradient)
                                            : AnyShapeStyle(AppTheme.cardBackgroundLight)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Anonymous Toggle
                    Toggle(isOn: $isAnonymous) {
                        HStack(spacing: 6) {
                            Image(systemName: isAnonymous ? "person.fill.questionmark" : "person.fill")
                                .foregroundStyle(isAnonymous ? .cyan : AppTheme.secondaryText)
                            Text("익명으로 작성")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(.cyan)

                    Divider().background(AppTheme.border)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("제목")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)

                        TextField("제목을 입력하세요", text: $title)
                            .textFieldStyle(.plain)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(12)
                            .background(AppTheme.cardBackgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("내용")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)

                        TextEditor(text: $content)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 200)
                            .background(AppTheme.cardBackgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 520, height: 520)
        .background(AppTheme.cardBackground)
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !content.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Edit Post Sheet
struct EditPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    let post: NewsPost
    var onSave: (NewsPost) -> Void
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var category: NewsCategory = .free
    @State private var isAnonymous: Bool = false
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text("글 수정")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Button("저장") {
                    guard canSubmit, !isSubmitting else { return }
                    isSubmitting = true
                    Task {
                        if let updated = await appState.updateNewsPost(postId: post.id, title: title, content: content, category: category, anonymous: isAnonymous) {
                            onSave(updated)
                            dismiss()
                        }
                        isSubmitting = false
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(canSubmit && !isSubmitting ? .cyan : AppTheme.tertiaryText)
                .disabled(!canSubmit || isSubmitting)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().background(AppTheme.border)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("카테고리")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                        HStack(spacing: 8) {
                            ForEach(NewsCategory.allCases.filter { $0 != .all }, id: \.self) { cat in
                                Button {
                                    category = cat
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.caption)
                                        Text(cat.rawValue)
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(category == cat ? .white : AppTheme.secondaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        category == cat
                                            ? AnyShapeStyle(cat.color.gradient)
                                            : AnyShapeStyle(AppTheme.cardBackgroundLight)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Toggle(isOn: $isAnonymous) {
                        HStack(spacing: 6) {
                            Image(systemName: isAnonymous ? "person.fill.questionmark" : "person.fill")
                                .foregroundStyle(isAnonymous ? .cyan : AppTheme.secondaryText)
                            Text("익명으로 작성")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(.cyan)

                    Divider().background(AppTheme.border)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("제목")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                        TextField("제목을 입력하세요", text: $title)
                            .textFieldStyle(.plain)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(12)
                            .background(AppTheme.cardBackgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("내용")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                        TextEditor(text: $content)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 200)
                            .background(AppTheme.cardBackgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 520, height: 520)
        .background(AppTheme.cardBackground)
        .onAppear {
            title = post.title
            content = post.content
            category = post.category
            isAnonymous = post.isAnonymous
        }
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !content.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

#Preview {
    NewsView()
        .environmentObject(AppState())
        .frame(width: 900, height: 700)
        .preferredColorScheme(.dark)
}
