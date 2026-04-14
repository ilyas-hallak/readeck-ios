var ExtensionPreprocessingJS = new Object();

ExtensionPreprocessingJS.run = function(arguments) {
    var html = document.documentElement.outerHTML;

    // Ensure charset is declared as utf-8 since the DOM always delivers Unicode.
    // Without this, backends may misinterpret the encoding based on the original
    // page's meta tag (e.g. iso-8859-1) even though the content is now utf-8.
    var charsetRe = /<meta[^>]+charset\s*=\s*["']?[^"'\s;>]+["']?[^>]*>/i;
    var utf8Meta = '<meta charset="utf-8">';
    if (charsetRe.test(html)) {
        html = html.replace(charsetRe, utf8Meta);
    } else if (/<head[^>]*>/i.test(html)) {
        html = html.replace(/<head[^>]*>/i, '$&' + utf8Meta);
    }

    arguments.completionFunction({
        "url": document.URL,
        "title": document.title,
        "html": html
    });
};
