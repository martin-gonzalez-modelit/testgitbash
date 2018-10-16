/**
 * Generic exception class. Intended to use within the AWS Amazon related clasess.
 *
 * @author Pablo Vigil <pablo.vigil@modelit.xyz>
 * @since 2016-9
 */
public class AWSException extends Exception {

    public class ServiceException extends Exception {
        public String code, message, resource, requestId;

        public ServiceException(Dom.XmlNode node) {
            String ns = node.getNamespace();
            code = getChildNodeText(node, ns, 'Code');
            message = getChildNodeText(node, ns, 'Message');
            resource = getChildNodeText(node, ns, 'Resource');
            requestId = getChildNodeText(node, ns, 'RequestId');
            setMessage(message);
        }

        private String getChildNodeText(Dom.XmlNode node, String ns, String name) {
            try {
                return node.getChildElement(name, ns).getText();
            } catch(Exception e) {
                return null;
            }
        }

        public String toString() {
            return JSON.serialize(this);
        }
    }

    public class IllegalArgumentException extends Exception {}

}