/**** Use this class to test separated code ****/

public with sharing class JustTestPurpose {
    public static final String OPTIONONE = 'option one';
    public static final String OPTIONTWO = 'option two';

    private static String xmlText = '<library>'
        + '<section>'
            + '<name>Science Fiction</name>'
            + '<book>'
                + '<title>Ender\'s Game</title>'
                + '<author>Orson Scott Card</author>'
            + '</book>'
            + '<book>'
                + '<title>Nightfall</title>'
                + '<author>Issac Asimov</author>'
            + '</book>'
        + '</section>'
        + '<section>'
            + '<name>Fantasy</name>'
            + '<book>'
                + '<title>The Hobbit</title>'
                + '<author>J.R.R. Tolkien</author>'
            + '</book>'
            + '<book>'
                + '<title>A Song of Fire and Ice</title>'
                + '<author>George R. R. Martin</author>'
            + '</book>'
           + '</section>'
        + '</library>';

    public static void caseTest() {
        switch on xmlText {
            when 'OPTIONONE' {
                System.debug('cacho option one');
            }
            when 'OPTIONTWO' {
                System.debug('cacho option two');
            }
        }
    }

    public static Library parse() {
        Dom.Document myXml = new Dom.Document();
        myXml.load(xmlText);

        Library result;

        for(Dom.XmlNode node : myXml.getRootElement().getChildElements()) {
            System.debug('cacho node ' + node.getName());
            if (node.getName() == 'library') {
                result = new Library();
                result.process(node);
            }
        }

        return result;
    }

    public Class Library{
        public List<Section> sections;

        public Library() { sections = new List<Section>(); }

        public void process(Dom.XmlNode inputNode) {
            for (Dom.XmlNode node : inputNode.getChildElements()) {
                if (node.getName() == 'section') {
                    Section entry = new Section();
                    entry.process(node);
                    sections.add(entry);
                }
            }
        }
    }

    public Class Section {
        public String name;
        public List<Book> books;

        public Section() { books = new List<Book>(); }

        public void process(Dom.XmlNode inputNode) {
            for (Dom.XmlNode node :inputNode.getChildElements()) {
                if (node.getName() == 'name') {
                    name = node.getText();
                } else if(node.getName() == 'book') {
                    Book singleBook = new Book();
                    singleBook.process(node);
                    books.add(singleBook);
                }
            }
            System.debug('cacho name ' + name);
        }
    }

    public class Book {
        String title;
        String author;

        public Book() { }

        public void process(Dom.XmlNode inputNode) {
            for (Dom.XmlNode node :inputNode.getChildElements()) {
                if (node.getName() == 'title') {
                    title = node.getText();
                } else if(node.getName() == 'author') {
                    author = node.getText();
                }
            }
            System.debug('cacho title ' + title);
            System.debug('cacho author ' + author);
        }
    }

}