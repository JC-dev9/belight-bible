import 'package:flutter/material.dart';
import '../../utils/theme.dart';
// Nota: Precisamos de aceder ao BibleRepository ou passar os dados.
// Para uma separação mais limpa, devemos passar os dados (lista de livros, dicionário de capítulos)
// ou continuar a referenciar o repositório se for um singleton (não é).
// Vamos passar os dados.

class BibleModals {
  
  static void showBookSelector(
      BuildContext context, {
      required Color backgroundColor,
      required Color textColor,
      required Color activeColor,
      required List<String> allBooks,
      required String selectedBook,
      required Function(String) onBookSelected,
    }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Livros',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: allBooks.length,
                  itemBuilder: (context, index) {
                    final book = allBooks[index];
                    final isSelected = book == selectedBook;
                    return ListTile(
                      title: Text(book,
                          style: TextStyle(
                              color: isSelected ? activeColor : textColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      trailing: isSelected
                          ? Icon(Icons.check, color: activeColor)
                          : null,
                      onTap: () {
                        onBookSelected(book);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showChapterSelector(
    BuildContext context, {
    required Color backgroundColor,
    required Color textColor,
    required Color activeColor,
    required String selectedBook,
    required int selectedChapter,
    required int maxChapters,
    required Function(int) onChapterSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Capítulos de $selectedBook',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: maxChapters,
                itemBuilder: (context, index) {
                  final chapter = index + 1;
                  final isSelected = chapter == selectedChapter;
                  return InkWell(
                    onTap: () {
                      onChapterSelected(chapter);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor
                            : textColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? null
                            : Border.all(color: textColor.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: TextStyle(
                            color: isSelected ? Colors.black : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showVersionSelector(
    BuildContext context, {
    required Color backgroundColor,
    required Color textColor,
    required Color activeColor,
    required String currentVersion,
    required Map<String, String> availableVersions,
    required Function(String) onVersionSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Versão da Bíblia',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...availableVersions.entries.map((entry) {
                final isSelected = currentVersion == entry.key;
                return ListTile(
                  title: Text(entry.value,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  trailing: isSelected
                      ? Icon(Icons.check, color: activeColor)
                      : null,
                  onTap: () {
                    if (!isSelected) {
                        onVersionSelected(entry.key);
                    }
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
