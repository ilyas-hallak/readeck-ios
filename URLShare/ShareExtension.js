var ExtensionPreprocessingJS = new Object();

ExtensionPreprocessingJS.run = function(arguments) {
    arguments.completionFunction({
        "url": document.URL,
        "title": document.title,
        "html": document.documentElement.outerHTML
    });
};
