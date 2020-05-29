extends HTTPRequest


var manifest: Dictionary
var contents: Dictionary
var last_response: Dictionary


func _ready():
    connect("request_completed", self, "get_response")


func load() -> Dictionary:
    """
    Async method to load all the contents files.
    Call with yield, example:
    var dict = yield($contentLoader.load(), "completed") 

    :return: A dictionary with each content file as value for all manifest keys.
    """
    manifest = get_manifest()

    for content in manifest:
        contents[content] = yield(load_content(manifest[content]), "completed")

    return contents


func load_content(config: Dictionary) -> Dictionary:
    """
    Load a single content by it config in the manifest.

    :param config: The config coming from the manifest values.
    :return: The dictionary with the respective content.
    """

    # TODO: Check each config key if exist and is in the correct type.
    # TODO: Cache the last response in a user:// path.
    # TODO: Use "Engine.editor_hint" to save the web request result in the local path.

    var keyResponse: Dictionary = yield(make_request(config["contentKeyApiUrl"]), "completed")
    var webContentKey: String = keyResponse["title"]
    if not config["key"] or webContentKey != config["key"]:
        config["key"] = webContentKey
        return yield(make_request(config["contentApiUrl"]), "completed")
    else:
        return local_content(config["localPath"])


func local_content(local_path: String) -> Dictionary:
    """
    Load the content locally in the config local path.

    :param local_path: A res:// path to a json TextFile.
    :return: The local json as dictionary.
    """

    # TODO: Check if read the file correctly.

    var file: File = File.new()
    file.open(local_path, File.READ)
    var json: JSONParseResult = JSON.parse(file.get_as_text())
    file.close()
    return json.result


func get_manifest() -> Dictionary:
    """
    Get the contents manifest in the script folder.

    :return: The manifest dictionary.
    """

    # TODO: Check if read the file correctly.

    var scriptPath: String = self.get_script().get_path()
    var manifestPath: String = str(scriptPath).replace("contentLoader.gd", "manifest.tres")
    var manifestFile: File = File.new()
    manifestFile.open(manifestPath, File.READ)
    var json: JSONParseResult = JSON.parse(manifestFile.get_as_text())
    manifestFile.close()
    return json.result


func make_request(url: String) -> Dictionary:
    """
    Make a async web request to a endpoint with a json response.

    :param url: The url to request for.
    :return: The json response as dictionary.
    """

    # TODO: Add Authorization request header.

    request(url)
    yield(self, "request_completed")
    return last_response


func get_response(result, response_code, headers, body):
    """
    Set the last_response value with the json response as dictionary.

    :param result:
    :param response_code: The http response status code.
    :param headers: The response headers.
    :param body: The response body.
    """

    # TODO: Check if the request fail.

    var json: JSONParseResult = JSON.parse(body.get_string_from_utf8())
    last_response = json.result
