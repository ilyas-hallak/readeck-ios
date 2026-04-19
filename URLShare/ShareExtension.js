var ExtensionPreprocessingJS = new Object();

ExtensionPreprocessingJS.run = function(arguments) {
    var html = document.documentElement.outerHTML;

    // Remove all charset declarations and inject a fresh utf-8 meta at the top
    // of <head>. The DOM always delivers Unicode so the content is always utf-8,
    // but leaving the original declaration (e.g. iso-8859-1) causes backends to
    // misinterpret the bytes. We strip all occurrences to handle pages where
    // WebKit normalises the DOM and produces multiple charset meta tags.
    html = html.replace(/<meta[^>]+charset[^>]*>/gi, '');
    html = html.replace(/(<head[^>]*>)/i, '$1<meta charset="utf-8">');

    arguments.completionFunction({
        "url": document.URL,
        "title": document.title,
        "html": html
    });
};
