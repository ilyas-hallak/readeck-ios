### Python: Step-by-step prompting for complex tasks

Source: https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model

This example demonstrates how to provide a detailed, step-by-step plan within a prompt to guide an on-device model through a complex task, reducing its reasoning burden.

```python
def analyze_home_decor(transactions, search_history):
    # Step 1: Choose four home furniture categories most relevant to this person.
    relevant_categories = select_relevant_categories(transactions, search_history, count=4)
    
    # Step 2: Recommend two more categories related to home-decor.
    recommended_categories = recommend_additional_categories(transactions, search_history, count=2)
    
    # Step 3: Return a list of relevant and recommended categories, ordered by most relevant to least.
    all_categories = relevant_categories + recommended_categories
    ordered_categories = order_categories_by_relevance(all_categories)
    
    return ordered_categories

# Placeholder functions for the actual logic
def select_relevant_categories(transactions, search_history, count):
    return ["Category A", "Category B", "Category C", "Category D"]
def recommend_additional_categories(transactions, search_history, count):
    return ["Category E", "Category F"]
def order_categories_by_relevance(categories):
    return categories
```

--------------------------------

### Initializing a Model Session with Instructions

Source: https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models

Shows how to initialize a `LanguageModelSession` with specific instructions to guide the model's behavior. The example sets instructions for suggesting related topics, keeping them concise and relevant to the user's input.

```swift
let instructions = """
    Suggest five related topics. Keep them concise (three to seven words) and make sure they \ 
    build naturally from the person's topic.
    """


let session = LanguageModelSession(instructions: instructions)


let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)
```

--------------------------------

### Initializer for DynamicGenerationSchema

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init%28type%3Aguides%3A%29

Creates a `DynamicGenerationSchema` from a `Generable` type and optional generation guides. This initializer requires Swift 5.9+ and is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
init<Value>(
    type: Value.Type,
    guides: [GenerationGuide<Value>] = []
) where Value : Generable
```

--------------------------------

### Few-Shot Prompting for Customer Generation (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model

This Swift code demonstrates few-shot prompting by providing example JSON structures of customer data to guide the on-device model in generating new customer profiles. It defines instructions with sample customer objects and expects the model to follow this pattern.

```swift
let instructions = """
    Create an NPC customer with a fun personality suitable for the dream realm. \
    Have the customer order coffee. Here are some examples to inspire you:

    {name: \"Thimblefoot\", imageDescription: \"A horse with a rainbow mane\", \
    coffeeOrder: \"I would like a coffee that's refreshing and sweet, like the grass in a summer meadow.\"}
    {name: \"Spiderkid\", imageDescription: \"A furry spider with a cool baseball cap\", \
    coffeeOrder: \"An iced coffee please, that's as spooky as I am!\"}
    {name: \"Wise Fairy\", imageDescription: \"A blue, glowing fairy that radiates wisdom and sparkles\", \
    coffeeOrder: \"Something simple and plant-based, please. A beverage that restores my wise energy.\"}
    """

```

--------------------------------

### Creating a Guide Macro

Source: https://developer.apple.com/documentation/foundationmodels/guide%28description%3A_%3A%29

Illustrates the creation of a Guide macro with a String description, allowing developers to specify guidance for value generation. This is a fundamental aspect of influencing property behaviors.

```swift
macro Guide(description: String)
```

--------------------------------

### Guide Macro

Source: https://developer.apple.com/documentation/foundationmodels/generationguide

Information about the Guide macro used for influencing property generation values.

```APIDOC
## Guide Macro

### Description
Allows for influencing the allowed values of properties of a `Generable` type.

### Method
- `macro Guide(description: String)`
- `macro Guide(description:_:)`

### Parameters

#### `Guide(description:)`
- **`description`** (String) - Required - A description of the generation rules.

#### `Guide(description:_:)`
- **`description`** (String) - Required - A description of the generation rules.

### Request Example
```json
{
  "example": "Not applicable for macros"
}
```

### Response
#### Success Response (200)
- **`Guide`** - A macro for defining generation constraints.
```

--------------------------------

### SystemLanguageModel.Adapter Initialization

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/init%28name%3A%29

This section details the initialization of the SystemLanguageModel.Adapter using the `init(name:)` method. It explains the parameters, potential errors, and provides an example.

```APIDOC
## `init(name:)`

### Description
Creates an adapter downloaded from the background assets framework.

Available for: iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+

### Method
`init(name: String) throws`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```json
{
  "name": "myAdapterName"
}
```

### Response
#### Success Response (200)
Initialization successful. The adapter is ready to be used.

#### Response Example
(No specific response body for initialization, success is indicated by the absence of an error.)

## Discussion
Throws:
An error of `AssetLoadingError` type when there are no compatible asset packs with this adapter name downloaded.

## See Also
### Creating an adapter
Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
`com.apple.developer.foundation-model-adapter`
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
`init(fileURL: URL) throws`
Creates an adapter from the file URL.
```

--------------------------------

### Create String Property with Guides

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/property/init%28name%3Adescription%3Atype%3Aguides%3A%29

Initializes a property with a string type, optionally including a description and an array of regular expressions to guide generation. Only the last regex in the guides array is applied.

```swift
init<RegexOutput>(
    name: String,
    description: String? = nil,
    type: String.Type,
    guides: [Regex<RegexOutput>] = []
)
```

--------------------------------

### Example Tool Implementation: FindContacts

Source: https://developer.apple.com/documentation/foundationmodels/tool

An example of how to implement the `Tool` protocol to create a tool that finds contacts.

```APIDOC
## Struct FindContacts

### Description
An example tool that finds a specified number of contacts. It demonstrates how to define arguments and the call method.

### Method
`func call(arguments: Arguments) async throws -> [String]`

### Endpoint
N/A (Struct Implementation)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
##### Arguments
- **count** (`Int`) - Required - The number of contacts to retrieve. Must be between 1 and 10.

### Request Example
```json
{
  "count": 3
}
```

### Response
#### Success Response (200)
- **[String]** - An array of strings, where each string represents a contact's full name.

#### Response Example
```json
[
  "Alice Wonderland",
  "Bob The Builder",
  "Charlie Chaplin"
]
```

### Error Handling
- **`Error`** - Can throw errors during contact fetching.
```

--------------------------------

### Swift Macro for Guided Generation

Source: https://developer.apple.com/documentation/foundationmodels/guide%28description%3A%29

The `Guide` macro, implemented in Swift, is used to influence the allowed values of properties belonging to a `Generable` type. This macro is available on iOS, iPadOS, macOS, and visionOS platforms starting from version 26.0.

```swift
@attached(peer)
macro Guide(description: String)
```

--------------------------------

### Example Usage of logFeedbackAttachment

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback

An example demonstrating how to use the LanguageModelSession to get a response and then log feedback with sentiment and issues.

```APIDOC
```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "What is the capital of France?")


// Create feedback for a problematic response.
let feedbackData = session.logFeedbackAttachment(
    sentiment: LanguageModelFeedback.Sentiment.negative,
    issues: [
        LanguageModelFeedback.Issue(
            category: .incorrect,
            explanation: "The model provided outdated information"
        )
    ],
    desiredOutput: Transcript.Entry.response(...)
)
```
```

--------------------------------

### Guide Macro Definition

Source: https://developer.apple.com/documentation/foundationmodels/guide%28description%3A_%3A%29

Defines the Guide macro, which accepts an optional description string and a regular expression to guide property value generation. This macro is applied at the peer level.

```swift
@attached(peer)
macro Guide<RegexOutput>(
    description: String? = nil,
    _ guides: Regex<RegexOutput>
)
```

--------------------------------

### Declare Maximum Value for Generation Guide (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/maximum%28_%3A%29

Defines a `GenerationGuide` with an inclusive maximum bound. This ensures that generated values do not exceed the specified limit. The example shows how to apply this to an `Int` property in a Swift struct.

```swift
@Generable
struct GameCharacter {
    @Guide(description: "A creative name appropriate for a fantasy RPG character")
    var name: String


    @Guide(description: "A level for the character", .maximum(100))
    var level: Int
}
```

--------------------------------

### LanguageModelSession.respond(to:schema:includeSchemaInPrompt:options:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Aschema%3Aincludeschemainprompt%3Aoptions%3A%29

Produces a generated content type as a response to a prompt and schema. This method allows for guided content generation based on a provided schema.

```APIDOC
## POST /websites/developer_apple_foundationmodels/respond

### Description
Produces a generated content type as a response to a prompt and schema. Allows for guided content generation based on a provided schema.

### Method
POST

### Endpoint
/websites/developer_apple_foundationmodels/respond

### Parameters
#### Query Parameters
- **prompt** (Prompt) - Required - A prompt for the model to respond to.
- **schema** (GenerationSchema) - Required - A schema to guide the output with.
- **includeSchemaInPrompt** (Bool) - Optional - Defaults to true. Inject the schema into the prompt to bias the model.
- **options** (GenerationOptions) - Optional - Options that control how tokens are sampled from the distribution the model produces.

### Request Body
```json
{
  "prompt": { ... },
  "schema": { ... },
  "includeSchemaInPrompt": true,
  "options": { ... }
}
```

### Response
#### Success Response (200)
- **GeneratedContent** (GeneratedContent) - The generated content conforming to the schema.

#### Response Example
```json
{
  "generatedContent": {
    "fields": {
      "exampleField": "exampleValue"
    }
  }
}
```

### Discussion
Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.
```

--------------------------------

### Implementing a Tool: FindContacts Example

Source: https://developer.apple.com/documentation/foundationmodels/tool

Provides an example implementation of the `Tool` protocol named `FindContacts`. It defines an `Arguments` struct for the count of contacts to retrieve and a `call` method that returns a list of formatted contact names. The `call` method is marked with `@Generable` and includes placeholder logic for fetching contacts.

```swift
struct FindContacts: Tool {
    let name = "findContacts"
    let description = "Find a specific number of contacts"


    @Generable
    struct Arguments {
        @Guide(description: "The number of contacts to get", .range(1...10))
        let count: Int
    }


    func call(arguments: Arguments) async throws -> [String] {
        var contacts: [CNContact] = []
        // Fetch a number of contacts using the arguments.
        let formattedContacts = contacts.map {
            "\($0.givenName) \($0.familyName)"
        }
        return formattedContacts
    }
}
```

--------------------------------

### Define a custom Generable data structure for cat profiles

Source: https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation

This example shows how to define a Swift `struct` named `CatProfile` that conforms to the `Generable` protocol. It uses the `@Generable` macro for the struct and the `@Guide` macro for properties like `age` and `profile` to provide descriptions and constraints, guiding the model's output.

```swift
@Generable(description: "Basic profile information about a cat")
struct CatProfile {
    // A guide isn't necessary for basic fields.
    var name: String


    @Guide(description: "The age of the cat", .range(0...20))
    var age: Int


    @Guide(description: "A one sentence profile about the cat's personality")
    var profile: String
}
```

--------------------------------

### SystemLanguageModel.Adapter - Getting the metadata

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter

Retrieves creator-defined metadata associated with the adapter.

```APIDOC
### Getting the metadata

#### Properties

- **`creatorDefinedMetadata`** ([String : Any])

Values read from the creator defined field of the adapter’s metadata.
```

--------------------------------

### Get Maximum Value Generation Guide Signature (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/maximum%28_%3A%29

Provides the static method signature for creating a `GenerationGuide` that enforces a maximum value for `Decimal` types. This is the core function used to define the upper limit for numerical generations.

```swift
static func maximum(_ value: Decimal) -> GenerationGuide<Decimal>
```

--------------------------------

### Define Model Behavior with Transcript.Instructions (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/instructions

Initialize Transcript.Instructions to define the model's behavior using natural language. This struct is crucial for guiding the model and mitigating prompt injection attacks. It takes an ID, segments describing the instructions, and tool definitions.

```swift
struct Instructions

init(id: String, segments: [Transcript.Segment], toolDefinitions: [Transcript.ToolDefinition])
```

--------------------------------

### Instantiate Content Tagging Model and Session - Swift

Source: https://developer.apple.com/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags

This snippet demonstrates how to create an instance of the on-device language model's content tagging use case and initialize a session with specific instructions for the model. It highlights the setup required before prompting the model for content tags.

```swift
// Create an instance of the on-device language model's content tagging use case.
let model = SystemLanguageModel(useCase: .contentTagging)


// Initialize a session with the model and instructions.
let session = LanguageModelSession(model: model, instructions: """
    Provide the two tags that are most significant in the context of topics.
    """
)
```

--------------------------------

### Define PromptRepresentable Protocol and Usage Example

Source: https://developer.apple.com/documentation/foundationmodels/promptrepresentable

Demonstrates the definition of the PromptRepresentable protocol and provides an example of a custom type conforming to it. The example shows how to create a struct 'FamousHistoricalFigure' that implements the 'promptRepresentation' property to format its data as a prompt string. It also includes a usage example with 'LanguageModelSession' to send this prompt to a language model.

```swift
protocol PromptRepresentable {
    var promptRepresentation: Prompt { get }
}

struct FamousHistoricalFigure: PromptRepresentable {
    var name: String
    var biggestAccomplishment: String


    var promptRepresentation: Prompt {
        """
        Famous Historical Figure:
        - name: (name)
        - best known for: (biggestAccomplishment)
        """
    }
}


let response = try await LanguageModelSession().respond {
    "Tell me more about..."
    FamousHistoricalFigure(
        name: "Albert Einstein",
        biggestAccomplishment: "Theory of Relativity"
    )
}
```

--------------------------------

### Define Generation Guide for Array Elements - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/element%28_%3A%29

The `element(_:)` method is used to apply specific generation guides to elements within an array. This is useful for controlling the type and range of values generated in a collection. The example demonstrates generating an array of integers within a specified range.

```swift
@Generable
struct FortuneCookie {
    @Guide(description: "A fortune from a fortune cookie")
    var name: String


    @Guide(description: "A list lucky numbers", .element(.range(0...9)), .count(4))
    var luckyNumbers: [Int]
}
```

--------------------------------

### Example Usage of logFeedbackAttachment in Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredoutput%3A%29

Demonstrates how to use the logFeedbackAttachment method to create feedback data for both helpful and problematic responses from a language model session. It shows how to create a session, get a response, and then log feedback with different parameters.

```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "What is the capital of France?")


// Create feedback for a helpful response.
let helpfulFeedbackData = session.logFeedbackAttachment(sentiment: .positive)


// Create feedback for a problematic response.
let problematicFeedbackData = session.logFeedbackAttachment(
    sentiment: .negative,
    issues: [
        LanguageModelFeedback.Issue(
            category: .incorrect,
            explanation: "The model provided outdated information"
        )
    ],
    desiredOutput: Transcript.Entry.response(...)
)
```

--------------------------------

### Structuring Model Interaction with Instructions

Source: https://developer.apple.com/documentation/foundationmodels/index

Provide detailed instructions to guide the model's behavior when processing prompts, ensuring it adheres to specific requirements or formats.

```swift
import Foundation

let instructions = Instructions(
    style: .concise,
    intent: "Summarize the following text into three bullet points."
)

let prompt = Prompt(text: "[Your long text here]", instructions: instructions)

// Example usage:
// let session = LanguageModelSession()
// let response = try await session.process(prompt: prompt)
```

--------------------------------

### Dynamically Build a Prompt with PromptBuilder

Source: https://developer.apple.com/documentation/foundationmodels/prompt

This example showcases the use of PromptBuilder to construct a prompt dynamically. It includes conditional logic to add extra text based on a Boolean variable, allowing for more flexible and state-aware prompts.

```swift
let responseShouldRhyme = true
let prompt = Prompt {
    "Answer the following question from the user: \(userInput)"
    if responseShouldRhyme {
        "Your response MUST rhyme!"
    }
}
```

--------------------------------

### Get SystemLanguageModel Availability (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift

Retrieves the availability status of the language model. This property is read-only and returns an enum value indicating the model's readiness on the system. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
final var availability: SystemLanguageModel.Availability { get }
```

--------------------------------

### Swift LanguageModelSession with Custom Instructions

Source: https://developer.apple.com/documentation/foundationmodels/instructions

Demonstrates how to initialize and use a `LanguageModelSession` in Swift with custom instructions. This snippet shows setting instructions, defining a prompt, and asynchronously requesting a response from the model, highlighting input and output flow.

```swift
let instructions = """
    Suggest related topics. Keep them concise (three to seven words) and make sure they \    build naturally from the person's topic.
    """


let session = LanguageModelSession(instructions: instructions)


let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)
```

--------------------------------

### Create and Use Generation Schema for Model Output (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation

This snippet shows how to create a `GenerationSchema` from a dynamically defined schema and then use it to guide the model's response. It includes error handling for schema creation and passing the schema to the model session.

```swift
let schema = try GenerationSchema(root: menuSchema, dependencies: [])

let response = try await session.respond(
    to: "The prompt you want to make.",
    schema: schema
)
```

--------------------------------

### Swift: Transcript.Entry.instructions(_:)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/instructions%28_%3A%29

Defines the `instructions` case for `Transcript.Entry`, used to pass developer-provided instructions to the Foundation model. Requires iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, or visionOS 26.0+.

```swift
case instructions(Transcript.Instructions)
```

--------------------------------

### Retrieve Supported Languages (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportedlanguages

This code snippet demonstrates how to access the `supportedLanguages` property to get a set of locales that the model supports. This property is available on iOS, iPadOS, macOS, Mac Catalyst, and visionOS platforms starting from version 26.0.

```swift
final var supportedLanguages: Set<Locale.Language> { get }
```

--------------------------------

### Accessing GenerationSchema in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generable/generationschema

This code snippet demonstrates how to access the static `generationSchema` property in Swift. This property provides an instance of `GenerationSchema`, which describes the properties of an object and guides on their values. It is available on iOS, iPadOS, macOS, Mac Catalyst, and visionOS starting from version 26.0.

```swift
static var generationSchema: GenerationSchema { get }
```

--------------------------------

### FoundationModels - Initializer

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init%28model%3Atools%3Ainstructions%3A%29

Initializes a new session for Foundation Models with specified model, tools, and instructions.

```APIDOC
## Initializer: init(model:tools:instructions:)

### Description
Starts a new session in a blank slate state with an instructions builder.

### Method
`convenience init`

### Parameters
#### Parameters
- **model** (SystemLanguageModel) - Optional - The language model to use for this session. Defaults to `.default`.
- **tools** ([any Tool]) - Optional - Tools to make available to the model for this session. Defaults to an empty array.
- **instructions** (InstructionsBuilder) - Required - Instructions that control the model’s behavior.

### Request Example
```swift
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    @InstructionsBuilder instructions: () throws -> Instructions
) rethrows
```

### Response
This initializer does not return a value directly but rather sets up a new session instance.
```

--------------------------------

### Creating Transcript Entry Types

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/response%28_%3A%29

Examples of creating different types of transcript entries, including instructions, prompts, tool calls, and tool outputs. These are used to build detailed interaction histories with foundation models.

```swift
case instructions(Transcript.Instructions)
case prompt(Transcript.Prompt)
case toolCalls(Transcript.ToolCalls)
case toolOutput(Transcript.ToolOutput)
```

--------------------------------

### Load and Use Adapted Model

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Loads a Foundation Model adapter, waits for its download to complete using `checkAdapterDownload`, and then adapts the base model with the downloaded adapter. Finally, it initializes a `LanguageModelSession` with the adapted model to start prompting.

```swift
// Load the adapter.
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


// Wait for download to complete.
if await checkAdapterDownload(name: "myAdapter") {
    // Adapt the base model with your adapter.
    let adaptedModel = SystemLanguageModel(adapter: adapter)
    
    // Start a session with the adapted model.
    let session = LanguageModelSession(model: adaptedModel)
    
    // Start prompting the adapted model.
}

```

--------------------------------

### Initialize and Download SystemLanguageModel Adapter

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Creates an instance of SystemLanguageModel.Adapter using the adapter's base name. If a compatible adapter is not found on the device, this automatically triggers a download of the adapter asset pack. This process can take time depending on network conditions.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")

```

--------------------------------

### Swift Generable Macro Usage with Struct and Enum

Source: https://developer.apple.com/documentation/foundationmodels/generable%28description%3A%29

Demonstrates applying the `@Generable` macro to a `NovelIdea` struct and a `Genre` enum. The struct uses the `@Guide` macro for its properties, showcasing guided generation.

```swift
@Generable
struct NovelIdea {
  @Guide(description: "A short title")
  let title: String


  @Guide(description: "A short subtitle for the novel")
  let subtitle: String


  @Guide(description: "The genre of the novel")
  let genre: Genre
}


@Generable
enum Genre {
  case fiction
  case nonFiction
}
```

--------------------------------

### Handle Model Refusals with Guided Generation in Swift

Source: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

Illustrates how to manage model refusals when using guided generation for Swift structures. This Swift code snippet shows how to catch `LanguageModelSession.GenerationError.refusal` errors and then asynchronously retrieve an explanation for the refusal, which can be displayed to the user.

```swift
do {
    let session = LanguageModelSession()
    let topic = ""  // A sensitive topic.
    let response = try session.respond(
        to: "List five key points about: \(topic)",
        generating: [String].self
    )
} catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
    // Generate an explanation for the refusal.
    if let message = try? await refusal.explanation {
        // Display the refusal message.
    }
}
```

--------------------------------

### Generate Float response with guided generation

Source: https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation

This code snippet demonstrates how to generate a response from a language model as a `Float` type instead of the default `String`. It uses the `respond` method with `Float.self` to specify the desired output type, leveraging the framework's guided generation capabilities.

```swift
let prompt = "How many tablespoons are in a cup?"
let session = LanguageModelSession(model: .default)


// Generate a response with the type `Float`, instead of `String`.
let response = try await session.respond(to: prompt, generating: Float.self)
```

--------------------------------

### Create Transcript with Initial Entries

Source: https://developer.apple.com/documentation/foundationmodels/transcript/init%28entries%3A%29

Initializes a new transcript with an optional sequence of entries. This initializer is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
init(entries: some Sequence<Transcript.Entry> = [])
```

--------------------------------

### Generate a custom data type response with guided generation

Source: https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation

This code snippet illustrates how to make a request to a language model using a custom Swift data type, `CatProfile`, for guided generation. By specifying `CatProfile.self` in the `respond` method, the model is prompted to return data structured according to the `CatProfile` definition, avoiding manual parsing.

```swift
// Generate a response using a custom type.
let response = try await session.respond(
    to: "Generate a cute rescue cat",
    generating: CatProfile.self
)
```

--------------------------------

### See Also: Building Instructions (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildexpression%28_%3A%29

This section lists related methods for building instructions. These include creating builders from arrays, blocks, conditional components (either/limited availability/optional), demonstrating various ways to construct complex instruction sets programmatically.

```swift
static func buildArray([some InstructionsRepresentable]) -> Instructions
```

```swift
static func buildBlock<each I>(repeat each I) -> Instructions
```

```swift
static func buildEither(first: some InstructionsRepresentable) -> Instructions
```

```swift
static func buildEither(second: some InstructionsRepresentable) -> Instructions
```

```swift
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
```

```swift
static func buildOptional(Instructions?) -> Instructions
```

--------------------------------

### Swift - LanguageModelSession.GenerationError.unsupportedGuide(_:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/unsupportedguide%28_%3A%29

Defines the `unsupportedGuide` error case for `LanguageModelSession.GenerationError`. This error is raised when a generation guide with an unsupported pattern is utilized within a language model session. It requires a `Context` object detailing the error's occurrence.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```

--------------------------------

### buildEither(second:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither%28second%3A%29

Creates an Instructions builder with the second component. This method is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```APIDOC
## POST /websites/developer_apple_foundationmodels/buildEither(second:)

### Description
Creates a builder with the second component.

### Method
POST

### Endpoint
/websites/developer_apple_foundationmodels/buildEither(second:)

### Parameters
#### Path Parameters
* None

#### Query Parameters
* None

#### Request Body
* **component** (some InstructionsRepresentable) - Required - The second component to be included in the instructions builder.

### Request Example
```json
{
  "component": { /* InstructionsRepresentable object */ }
}
```

### Response
#### Success Response (200)
* **Instructions** (Instructions) - The created Instructions builder.

#### Response Example
```json
{
  "Instructions": { /* Instructions object */ }
}
```
```

--------------------------------

### Building Instructions from Expressions and Limited Availability

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder

Explains the methods for building instructions from individual expressions and for handling prompts with limited availability, ensuring proper construction in various scenarios.

```swift
static func buildExpression(_:) -> Instructions
static func buildLimitedAvailability(_: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### buildArray(_:)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildarray%28_%3A%29

Creates a builder with an array of prompts. This method is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```APIDOC
## POST /websites/developer_apple_foundationmodels/buildArray

### Description
Creates a builder with an array of prompts. This method is used to construct complex prompts by combining multiple prompt elements.

### Method
POST

### Endpoint
/websites/developer_apple_foundationmodels/buildArray

### Parameters
#### Request Body
- **prompts** (Array<PromptRepresentable>) - Required - An array of prompts to be combined.

### Request Example
```json
{
  "prompts": [
    {
      "type": "text",
      "content": "Hello"
    },
    {
      "type": "text",
      "content": "World"
    }
  ]
}
```

### Response
#### Success Response (200)
- **prompt** (Prompt) - The constructed prompt object.

#### Response Example
```json
{
  "prompt": {
    "type": "composite",
    "elements": [
      {
        "type": "text",
        "content": "Hello"
      },
      {
        "type": "text",
        "content": "World"
      }
    ]
  }
}
```
```

--------------------------------

### TextSegment Initializer

Source: https://developer.apple.com/documentation/foundationmodels/transcript/textsegment/init%28id%3Acontent%3A%29

Initializes a new instance of Transcript.TextSegment with an ID and content.

```APIDOC
## init(id:content:)

### Description
Initializes a new instance of Transcript.TextSegment with an identifier and textual content.

### Method
Initializer

### Endpoint
N/A (Initializes an object)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **id** (String) - Optional - A unique identifier for the text segment. Defaults to a new UUID string.
- **content** (String) - Required - The textual content of the segment.

### Request Example
```json
{
  "id": "some-unique-id",
  "content": "This is the text content of the segment."
}
```

### Response
#### Success Response (200)
N/A (This is an initializer, it creates an object in memory)

#### Response Example
N/A
```

--------------------------------

### Prewarm Foundation Model Session in Swift

Source: https://developer.apple.com/documentation/foundationmodels/analyzing-the-runtime-performance-of-your-foundation-models-app

This snippet demonstrates how to initialize a Foundation Model session and prewarm it to optimize model loading. Prewarming loads the model in advance, reducing latency when a response is actually requested. It's recommended to prewarm at least one second before the first `respond` method call. The `promptPrefix` parameter can further enhance performance by providing context for anticipated requests.

```swift
// Create a session.
var session = LanguageModelSession()


// Prewarm the session when a person navigates to a screen that uses the session.
session.prewarm()

// Prewarm with context about the likely request.
session.prewarm(promptPrefix: "Generate a travel itinerary for")

```

--------------------------------

### GeneratedContent.Kind.array(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/array%28_%3A%29

Represents an array of `GeneratedContent` elements. This case is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```APIDOC
## GeneratedContent.Kind.array(_:)

### Description
Represents an array of `GeneratedContent` elements.

### Method
Associated Value Constructor

### Endpoint
N/A (Enum Case)

### Parameters
#### Associated Value
- **elements** (Array<GeneratedContent>) - Required - An array of `GeneratedContent` instances.

### Request Example
```swift
let myArray: [GeneratedContent] = [...] // Your array of GeneratedContent
let arrayKind = GeneratedContent.Kind.array(myArray)
```

### Response
#### Success Response (N/A)
This is an enum case definition, not an API endpoint.

#### Response Example
```swift
// Example usage within a GeneratedContent structure:
let contentArray = GeneratedContent.Kind.array([GeneratedContent(...), GeneratedContent(...)]) 
let generatedContent = GeneratedContent(kind: contentArray)
```

### See Also
- `GeneratedContent.Kind.bool(_:)`
- `GeneratedContent.Kind.null`
- `GeneratedContent.Kind.number(_:)`
- `GeneratedContent.Kind.string(_:)`
- `GeneratedContent.Kind.structure(properties:orderedKeys:)`
```

--------------------------------

### Get Recovery Suggestion (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

A computed property that provides a suggestion on how to handle the error. This is part of the LocalizedError conformance.

```swift
var recoverySuggestion: String?

```

--------------------------------

### Define Generable Type with @Generable Macro - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generable

This Swift code snippet demonstrates how to define a struct 'SearchSuggestions' that conforms to the Generable protocol using the '@Generable' macro. It includes nested structs and properties annotated with '@Guide' to guide the model's generation process. This allows the model to generate an instance of 'SearchSuggestions' in response to prompts.

```swift
@Generable
struct SearchSuggestions {
    @Guide(description: "A list of suggested search terms.", .count(4))
    var searchTerms: [SearchTerm]
    @Generable
    struct SearchTerm {
        // Use a generation identifier for data structures the framework generates.
        var id: GenerationID
        @Guide(description: "A two- or three- word search term, like 'Beautiful sunsets'.")
        var searchTerm: String
    }
}
```

--------------------------------

### Choose Compatible Adapter at Runtime (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

This Swift code snippet is used within the `BackgroundDownloadHandler.swift` file generated by Xcode for asset-downloader extensions. It determines whether to download an asset pack based on device compatibility using the `SystemLanguageModel.Adapter.isCompatible` method. It also includes an example of filtering out non-adapter assets like shaders.

```swift
func shouldDownload(_ assetPack: AssetPack) -> Bool {
    // Check for any non-adapter assets your app has, like shaders. Remove the
    // check if your app doesn't have any non-adapter assets.
    if assetPack.id.hasPrefix("mygameshader") {
        // Return false to filter out asset packs, or true to allow download.
        return true
    }


    // Use the Foundation Models framework to check adapter compatibility with the runtime device.
    return SystemLanguageModel.Adapter.isCompatible(assetPack)
}
```

--------------------------------

### element(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/element%28_%3A%29

Enforces a guide on the elements within the array. This method is used to apply specific generation rules to each item contained in an array.

```APIDOC
## static func element<Element>(_ guide: GenerationGuide<Element>) -> GenerationGuide<[Element]> where Value == [Element]

### Description
Enforces a guide on the elements within the array.

### Method
`static func`

### Endpoint
N/A (This is a static method for defining generation guides)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
@Guide(description: "A list lucky numbers", .element(.range(0...9)), .count(4))
var luckyNumbers: [Int]
```

### Response
#### Success Response (200)
N/A (This is a static method for defining generation guides)

#### Response Example
N/A
```

--------------------------------

### Initialize SystemLanguageModel Adapter with Local URL

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Initializes a `SystemLanguageModel.Adapter` using a local file URL. This requires the absolute path to the `.fmadapter` package. It's used for testing adapters locally before deployment.

```swift
// The absolute path to your adapter.
let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")


// Initialize the adapter by using the local URL.
let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)
```

--------------------------------

### Create Generated Content with init(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28_%3A%29

This initializer creates a `GeneratedContent` object from an existing `GeneratedContent` value. It's a fundamental part of the `Generable` protocol and is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
init(_ content: GeneratedContent) throws
```

--------------------------------

### Get Error Description (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

A computed property that returns a string representation of the error description. This is part of the LocalizedError conformance.

```swift
var errorDescription: String?

```

--------------------------------

### LanguageModelFeedback.Issue.Category.unhelpful

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/unhelpful

This section details the 'unhelpful' category for reporting issues with language model responses. It explains what constitutes an unhelpful response and provides examples.

```APIDOC
## LanguageModelFeedback.Issue.Category.unhelpful

### Description
This API category is used to report that a language model's response was not helpful. This can occur when the model provides incomplete information, such as listing ingredients for a recipe without specifying amounts.

### Method
N/A (This is a descriptive category, not a direct API endpoint)

### Endpoint
N/A

### Parameters
N/A

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A
```

--------------------------------

### Initialize LanguageModelSession with Instructions (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init%28model%3Atools%3Ainstructions%3A%29

Initializes a new `LanguageModelSession` instance. It takes a language model, an array of tools, and a closure that builds instructions for the model. The `instructions` parameter uses a custom `InstructionsBuilder` for a declarative way to define model behavior.

```swift
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    @InstructionsBuilder instructions: () throws -> Instructions
) rethrows
```

--------------------------------

### LanguageModelSession.GenerationError.Refusal - explanation

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal/explanation

Retrieves an explanation for why the model refused to respond. This property is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS, starting from version 26.0.

```APIDOC
## GET /websites/developer_apple_foundationmodels/explanation

### Description
This endpoint (or property) provides a structured explanation for why a language model refused to generate a response. It is part of the `LanguageModelSession.GenerationError.Refusal` type.

### Method
GET

### Endpoint
`/websites/developer_apple_foundationmodels/explanation`

### Parameters

#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
This is an instance property, so no explicit request is made. It is accessed via an existing `LanguageModelSession.GenerationError.Refusal` object.

### Response
#### Success Response (200)
- **explanation** (LanguageModelSession.Response<String>) - An explanation for why the model refused to respond.

#### Response Example
```json
{
  "explanation": "The model refused to respond due to a violation of content policies."
}
```
```

--------------------------------

### Initializer: init(fileURL:)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/init%28fileurl%3A%29

Creates an adapter for the system language model from a given file URL. This initializer may throw an `AssetLoadingError` if the provided file URL is invalid.

```APIDOC
## init(fileURL:)

### Description
Creates an adapter from the file URL.

### Method
`init(fileURL: URL) throws`

### Endpoint
N/A (Initializers are not endpoints)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let adapter = try SystemLanguageModel.Adapter(fileURL: myFileURL)
```

### Response
#### Success Response (200)
N/A (Initializers do not return HTTP responses)

#### Response Example
N/A

### Discussion
Throws an error of `AssetLoadingError` type when `fileURL` is invalid.
```

--------------------------------

### Initialize Tool Definition with Name, Description, and Parameters

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition/init%28name%3Adescription%3Aparameters%3A%29

This initializer is used to create a new tool definition. It requires a name, a description, and a schema for its parameters. This is fundamental for defining how a foundation model can interact with custom tools. Available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
init(
    name: String,
    description: String,
    parameters: GenerationSchema
)
```

--------------------------------

### Access Recovery Suggestion

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror

Provides a suggestion on how to resolve the LanguageModelSession.GenerationError. This is useful for guiding the user or developer towards a solution and is part of the LocalizedError protocol.

```swift
var recoverySuggestion: String?
```

--------------------------------

### Generable Macro

Source: https://developer.apple.com/documentation/foundationmodels/generable%28description%3A%29

This macro can be applied to structures and enumerations to conform them to the Generable protocol. It allows for guided generation of content based on provided descriptions.

```APIDOC
## Generable Macro

### Description
Conforms a type to the `Generable` protocol. This macro is applicable to structures and enumerations, facilitating guided generation processes.

### Method
Macro Declaration

### Endpoint
N/A (This is a Swift macro, not a REST endpoint)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
@Generable
struct NovelIdea {
  @Guide(description: "A short title")
  let title: String

  @Guide(description: "A short subtitle for the novel")
  let subtitle: String

  @Guide(description: "The genre of the novel")
  let genre: Genre
}

@Generable
enum Genre {
  case fiction
  case nonFiction
}
```

### Response
#### Success Response (200)
N/A (This is a compile-time macro, not an API response)

#### Response Example
N/A
```

--------------------------------

### Creating content from properties with combining closure

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28properties%3Aid%3A%29

Details on creating generated content from a sequence of properties, using a closure to handle duplicate keys.

```APIDOC
## init<S>(properties: S, id: GenerationID?, uniquingKeysWith: (GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent) rethrows

### Description
Creates new generated content from the key-value pairs in the given sequence, using a combining closure to determine the value for any duplicate keys.

### Method
Initializer

### Endpoint
N/A (This is an initializer, not a REST endpoint)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **properties** (S where S : Sequence, S.Element == (String, any ConvertibleToGeneratedContent)) - Required - A sequence of key-value pairs.
- **id** (GenerationID?) - Optional - An optional identifier for the generated content.
- **uniquingKeysWith** ((GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent) - Required - A closure that combines values for duplicate keys.

### Request Example
```swift
let generatedContent = GeneratedContent(properties: [("key1", "value1"), ("key2", 123)], id: someGenerationID) { existing, new in new } // Example combining closure
```

### Response
#### Success Response (200)
N/A (This is an initializer, not a request that returns a response)

#### Response Example
N/A
```

--------------------------------

### LanguageModelSession - respond Method

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Agenerating%3Aincludeschemainprompt%3Aoptions%3A%29

The `respond` method allows you to get a generable object as a response to a prompt. You can specify the expected content type, whether to include the schema in the prompt, and generation options.

```APIDOC
## POST /foundation_models/language_model_session/respond

### Description
Produces a generable object as a response to a prompt. This method is available for iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

### Method
POST

### Endpoint
`/foundation_models/language_model_session/respond`

### Parameters
#### Request Body
- **prompt** (Prompt) - Required - A prompt for the model to respond to.
- **type** (Content.Type) - Optional - A type to produce as the response. Defaults to `Content.self`.
- **includeSchemaInPrompt** (Bool) - Optional - Inject the schema into the prompt to bias the model. Defaults to `true`.
- **options** (GenerationOptions) - Optional - Options that control how tokens are sampled from the distribution the model produces. Defaults to `GenerationOptions()`.

### Request Example
```json
{
  "prompt": {
    "text": "Tell me a story about a brave knight."
  },
  "type": "String",
  "includeSchemaInPrompt": true,
  "options": {
    "temperature": 0.7,
    "topK": 50
  }
}
```

### Response
#### Success Response (200)
- **response** (LanguageModelSession.Response<Content>) - Contains the generated content and associated metadata.

#### Response Example
```json
{
  "response": {
    "output": {
      "text": "Once upon a time, in a land filled with mystical creatures, lived a brave knight named Sir Reginald..."
    },
    "usedSchema": {
      "type": "string"
    }
  }
}
```

### Discussion
Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

### See Also
- `func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>`
- `func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>`
- `func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>`
- `func respond(to:options:)`
- `func respond(to:schema:includeSchemaInPrompt:options:)`
- `struct Prompt`
- `struct Response`
- `struct GenerationOptions`
```

--------------------------------

### SystemLanguageModel.Adapter.AssetError.Context Structure

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror/context

Details the structure of the Context, which provides information about the environment in which an asset error occurred. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```APIDOC
## SystemLanguageModel.Adapter.AssetError.Context

### Description
The context in which the error occurred.

### Availability
iOS 26.0+<br>iPadOS 26.0+<br>Mac Catalyst 26.0+<br>macOS 26.0+<br>visionOS 26.0+

### Structure
```swift
struct Context
```

### Topics
#### Creating a context
- `init(debugDescription: String)`
  Initializes a new instance of `Context` with a debug description.

#### Getting the debug description
- `let debugDescription: String`
  A debug description to help developers diagnose issues during development.

### Relationships
#### Conforms To
- `Sendable`
- `SendableMetatype`

### See Also
#### Getting the asset errors
- `case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)`
  An error that happens if there are no compatible adapters for the current system base model.
- `case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)`
  An error that happens if the provided adapter name is invalid.
- `case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)`
  An error that happens if the provided asset files are invalid.
```

--------------------------------

### SystemLanguageModel.Guardrails Initialization

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails

This section details how to initialize the Guardrails with different settings.

```APIDOC
## SystemLanguageModel.Guardrails

Guardrails flag sensitive content from model input and output.

### Getting the guardrail types

* `static let default`: SystemLanguageModel.Guardrails
  Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a `LanguageModelSession.GenerationError.guardrailViolation` error.

* `static let permissiveContentTransformations`: SystemLanguageModel.Guardrails
  Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.

### Loading the model with a use case

* `convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)`
  Creates a system language model for a specific use case.
```

--------------------------------

### Instance Property: toolName

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall/toolname

Retrieves the name of the tool being invoked. Available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```APIDOC
## Instance Property: toolName

### Description
The name of the tool being invoked.

### Availability
iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+

### Type
`String`

### Example
```swift
var toolName: String
```

## See Also
### Inspecting a tool call
`var arguments: GeneratedContent`
Arguments to pass to the invoked tool.
Current page is toolName
```

--------------------------------

### Getting Instructions Representation

Source: https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable

Provides the 'instructionsRepresentation' computed property, which returns an instance of the 'Instructions' type. This property is required by the InstructionsRepresentable protocol and has a default implementation.

```swift
var instructionsRepresentation: Instructions { get }

```

--------------------------------

### Create String-Type Property

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/property

Initializes a property with a string type, allowing for optional descriptions and guides. This is a common use case for defining string-based fields in a generation schema.

```swift
init(name: String, description: String?, type: String, guides: [String]? = nil)
```

--------------------------------

### DynamicGenerationSchema Initialization

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init%28name%3Adescription%3Aproperties%3A%29

This section details the initializer for creating a dynamic generation schema with a name, optional description, and properties.

```APIDOC
## init(name:description:properties:)

### Description
Creates an object schema.

### Method
Initializer

### Endpoint
N/A (This is Swift API documentation)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
init(
    name: String,
    description: String? = nil,
    properties: [DynamicGenerationSchema.Property]
)
```

### Response
#### Success Response (200)
N/A (This is Swift API documentation)

#### Response Example
N/A (This is Swift API documentation)

## Parameters 

`name`
    
A name this dynamic schema can be referenced by.

`description`
    
A natural language description of this schema.

`properties`
    
The properties to associated with this schema.

## See Also
### Creating a dynamic schema
`init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`
Creates an array schema.
`init(name:description:anyOf:)`
Creates an any-of schema.
`init(referenceTo: String)`
Creates an refrence schema.
`init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])`
Creates a schema from a generable type and guides.
`struct Property`
A property that belongs to a dynamic generation schema.
```

--------------------------------

### Swift: Access Prompt Representation

Source: https://developer.apple.com/documentation/foundationmodels/promptrepresentable/promptrepresentation-2c9rm

Accesses the promptRepresentation instance property to get a representation of a prompt. This property is read-only and returns a value of type Prompt.

```swift
var promptRepresentation: Prompt { get }
```

--------------------------------

### Swift: Build Limited Availability Instruction

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional%28_%3A%29

The `buildLimitedAvailability(_:)` static method constructs an `Instructions` builder for prompts that have limited availability. This allows for specifying instructions that might only be applicable under certain conditions or on specific platforms. It takes a `some InstructionsRepresentable` component.

```swift
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
```

--------------------------------

### Transcript.Entry.instructions(_:)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/instructions%28_%3A%29

Represents instructions provided by the developer within a transcript entry.

```APIDOC
## Transcript.Entry.instructions(_:)

### Description
Instructions, typically provided by you, the developer.

### Method
N/A (This is a Swift enum case)

### Endpoint
N/A

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (N/A)
This is an enum case, not an API endpoint.

#### Response Example
None

## See Also
### Creating an entry
`case prompt(Transcript.Prompt)`
A prompt, typically sourced from an end user.
`case response(Transcript.Response)`
A response from the model.
`case toolCalls(Transcript.ToolCalls)`
A tool call containing a tool name and the arguments to invoke it with.
`case toolOutput(Transcript.ToolOutput)`
An tool output provided back to the model.
```

--------------------------------

### Swift: Respond to a prompt (String output)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28generating%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

This Swift function generates a response to a prompt, specifically returning a `String`. It utilizes the `GenerationOptions` and the prompt itself to guide the model's output. This is a simpler overload of the `respond` method.

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
```

--------------------------------

### Produce Model Response with Prompt and Options

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Aoptions%3A%29

This Swift code snippet demonstrates how to use the 'respond(to:options:)' method to get a text response from a language model. It requires a 'Prompt' object and can optionally be configured with 'GenerationOptions'. The method is asynchronous and can throw errors.

```swift
@discardableResult nonisolated(nonsending)
final func respond(
    to prompt: Prompt,
    options: GenerationOptions = GenerationOptions()
) async throws -> LanguageModelSession.Response<String>
```

--------------------------------

### Define LanguageModelSession Class

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

Declares the LanguageModelSession class, which is central to interacting with language models. This class is available across multiple Apple platforms starting from specific OS versions.

```swift
final class LanguageModelSession
```

--------------------------------

### Swift: Arguments for Tool Invocation

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall/arguments

The 'arguments' property is a GeneratedContent instance used to pass arguments to an invoked tool. It is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
var arguments: GeneratedContent { get set }
```

--------------------------------

### Prompt Structure and Initialization

Source: https://developer.apple.com/documentation/foundationmodels/prompt

This section details the structure of the Prompt object and how to initialize it, either from a string literal or using a PromptBuilder for dynamic content.

```APIDOC
## Prompt API Documentation

### Description
Represents a prompt from a person to the model. Prompts can contain text from the user, an outside source, or directly from people using your app. They play a crucial role in steering the model's response and consuming tokens within the session's context window.

### Topics

#### Creating a Prompt

##### `init(_:)`
Initializes a `Prompt` from a string literal.

```swift
let prompt = Prompt("What are miniature schnauzers known for?")
```

##### Using `PromptBuilder`
Dynamically control the prompt's content based on your app's state using `PromptBuilder`.

```swift
let responseShouldRhyme = true
let prompt = Prompt {
    "Answer the following question from the user: \(userInput)"
    if responseShouldRhyme {
        "Your response MUST rhyme!"
    }
}
```

### Important Considerations

- **Context Window**: All input to the model, including `Prompt` objects, contributes to the context window of the `LanguageModelSession`. Exceeding this limit can result in `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`.

- **Token Consumption**: To reduce prompt size and token consumption:
  - Write shorter prompts.
  - Provide only necessary information.
  - Use concise and imperative language.
  - Use clear verbs like "Generate", "List", or "Summarize".
  - Specify the target response length, e.g., "In three sentences".

- **Session Management**: If prompts repeatedly cause the session to exceed the context window, create a new `LanguageModelSession` instance.

### Related Types

- `struct PromptBuilder`: A type that represents a prompt builder.
- `protocol PromptRepresentable`: A type whose value can represent a prompt.
- `class LanguageModelSession`: An object representing a session that interacts with a language model.
- `struct Instructions`: Defines the model's intended behavior on prompts.
- `struct Transcript`: A history of entries reflecting an interaction with a session.
- `struct GenerationOptions`: Options controlling how the model generates its response.
```

--------------------------------

### Transcript.Segment.structure(_:)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/segment/structure%28_%3A%29

This section details the `structure(_:)` case of the `Transcript.Segment` enum, used to represent a segment containing structured content. It specifies the required parameters and provides an example of its usage.

```APIDOC
## Transcript.Segment.structure(_:)

### Description
A segment containing structured content.

### Method
Associated Value (within an enum case)

### Endpoint
N/A (This is a Swift enum case definition, not a REST API endpoint)

### Parameters
#### Associated Value
- **structuredSegment** (Transcript.StructuredSegment) - Required - The structured segment data.

### Request Example
```swift
let structuredContent = Transcript.Segment.structure(Transcript.StructuredSegment(...))
```

### Response
#### Success Response (N/A - This is a code definition)
N/A

#### Response Example
```swift
case structure(Transcript.StructuredSegment)
```

## See Also
### Creating a segment
`case text(Transcript.TextSegment)`
A segment containing text.
Current page is Transcript.Segment.structure(_:)
```

--------------------------------

### Instance Property: promptRepresentation

Source: https://developer.apple.com/documentation/foundationmodels/promptrepresentable/promptrepresentation

This section describes the `promptRepresentation` instance property, which provides an instance that represents a prompt. It is available across multiple Apple platforms starting from iOS 26.0.

```APIDOC
## Instance Property: promptRepresentation

### Description
An instance that represents a prompt.

### Availability
iOS 26.0+ iPadOS 26.0+ Mac Catalyst 26.0+ macOS 26.0+ visionOS 26.0+

### Declaration
```swift
@PromptBuilder
var promptRepresentation: Prompt { get }
```

### Details
**Required** Default implementation provided.

## Default Implementations
### PromptRepresentable Implementations
`var promptRepresentation: Prompt`
An instance that represents a prompt.
Current page is promptRepresentation
```

--------------------------------

### Building Instructions

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither%28second%3A%29

Provides details on various methods for constructing Instructions, including array, block, conditional, and optional components.

```APIDOC
## API Endpoints for Building Instructions

### buildArray
Creates a builder with an array of prompts.

**Method:** POST
**Endpoint:** /websites/developer_apple_foundationmodels/buildArray
**Parameters:**
* **prompts** (Array<some InstructionsRepresentable>) - Required - An array of prompts to build.

### buildBlock
Creates a builder with a block of instructions.

**Method:** POST
**Endpoint:** /websites/developer_apple_foundationmodels/buildBlock
**Parameters:**
* **instructions** (repeat each I) - Required - A block of instructions.

### buildEither(first:)
Creates a builder with the first component.

**Method:** POST
**Endpoint:** /websites/developer_apple_foundationmodels/buildEither(first:)
**Parameters:**
* **first** (some InstructionsRepresentable) - Required - The first component to build.

### buildExpression
Creates a builder with a prompt expression.

**Method:** POST
**Endpoint:** /websites/developer_apple_foundationmodels/buildExpression
**Parameters:**
* **expression** (any) - Required - The prompt expression.

### buildLimitedAvailability
Creates a builder with a limited availability prompt.

**Method:** POST
**Endpoint:** /websites/developer_apple_foundationmodels/buildLimitedAvailability
**Parameters:**
* **prompt** (some InstructionsRepresentable) - Required - The prompt with limited availability.

### buildOptional
Creates a builder with an optional component.

**Method:** POST
**Endpoint:** /websites/developer_apple_foundationmodels/buildOptional
**Parameters:**
* **optional_prompt** (Instructions?) - Required - An optional Instructions component.
```

--------------------------------

### Declare Transcript.ToolCalls Structure

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcalls

Defines the `ToolCalls` structure, which serves as a collection for model-generated tool calls. This structure is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
struct ToolCalls
```

--------------------------------

### SystemLanguageModel.Adapter - Prepare the adapter

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter

Prepares an adapter before it can be used with a `LanguageModelSession`. This is particularly important if your adapter has a draft model.

```APIDOC
### Prepare the adapter

#### Method

- **`func compile() async throws`**

Prepares an adapter before being used with a `LanguageModelSession`. You should call this if your adapter has a draft model.
```

--------------------------------

### Create String Enumeration Schema - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/init%28type%3Adescription%3Aanyof%3A%29

Initializes a generation schema for a string enumeration. It takes the type it represents, an optional description, and an array of string choices for the enumeration. This initializer is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
init(
    type: any Generable.Type,
    description: String? = nil,
    anyOf choices: [String]
)
```

--------------------------------

### Swift: Build Expression Instruction

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional%28_%3A%29

The `buildExpression(_:)` static method creates an `Instructions` builder from a single prompt expression. This is a fundamental way to include individual prompts within an instruction sequence. It takes a `some InstructionsRepresentable` as input.

```swift
static buildExpression(_:)
```

--------------------------------

### Define a Model Response in Transcript Entry

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/response%28_%3A%29

This code defines the `response` case for a `Transcript.Entry`, which encapsulates a response from a model. It is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
case response(Transcript.Response)
```

--------------------------------

### GenerationGuide Methods

Source: https://developer.apple.com/documentation/foundationmodels/generationguide

This section details the various static methods available on the GenerationGuide struct to enforce specific generation constraints.

```APIDOC
## GenerationGuide Static Methods

### Description
Methods to define rules and constraints for value generation.

### Methods
- `pattern<Output>(Regex<Output>) -> GenerationGuide<String>`
- `element<Element>(GenerationGuide<Element>) -> GenerationGuide<[Element]>`
- `count(_:)`
- `constant(String) -> GenerationGuide<String>`
- `anyOf([String]) -> GenerationGuide<String>`
- `range(_:)`
- `minimum(_:)`
- `minimumCount<Element>(Int) -> GenerationGuide<[Element]>`
- `maximum(_:)`
- `maximumCount<Element>(Int) -> GenerationGuide<[Element]>`

### Parameters

#### `pattern`
- **`regex`** (Regex<Output>) - Required - The regular expression pattern to enforce.

#### `element`
- **`guide`** (GenerationGuide<Element>) - Required - The guide to enforce on each element of an array.

#### `count`
- **`count`** (Int) - Required - The exact number of elements required in an array.

#### `constant`
- **`value`** (String) - Required - The exact string value to enforce.

#### `anyOf`
- **`values`** ([String]) - Required - An array of strings, one of which must be matched.

#### `range`
- **`range`** (Range<T>) - Required - The range that values must fall within.

#### `minimum`
- **`value`** (Comparable) - Required - The minimum allowed value.

#### `minimumCount`
- **`count`** (Int) - Required - The minimum number of elements required in an array.

#### `maximum`
- **`value`** (Comparable) - Required - The maximum allowed value.

#### `maximumCount`
- **`count`** (Int) - Required - The maximum number of elements allowed in an array.

### Request Example
```json
{
  "example": "Not applicable for static methods"
}
```

### Response
#### Success Response (200)
- **`GenerationGuide<T>`** - A GenerationGuide instance configured with the specified constraints.
```

--------------------------------

### Define Context Structure

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror/context

Defines the `Context` structure used to represent the error context for asset-related issues within the SystemLanguageModel adapter. It is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
struct Context
```

--------------------------------

### Define LanguageModelFeedback.Sentiment Enumeration

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment

Defines the possible sentiment values for a language model's response. This enumeration is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
enum Sentiment
```

--------------------------------

### Swift: Instance Method respond(options:prompt:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28options%3Aprompt%3A%29

This Swift code defines the `respond` instance method for Foundation Models, which takes optional `GenerationOptions` and a closure returning a `Prompt` to generate a text response. It returns a `LanguageModelSession.Response<String>` asynchronously and can throw errors. The method is marked as discardable and non-sending.

```swift
@discardableResult nonisolated(nonsending)
final func respond(
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
) async throws -> LanguageModelSession.Response<String>
```

--------------------------------

### Create Limited Availability Prompt (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildlimitedavailability%28_%3A%29

This method creates a prompt builder specifically for prompts with limited availability. It takes a `PromptRepresentable` as input and returns a `Prompt` object. This functionality is available across multiple Apple platforms starting from version 26.0.

```swift
static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt
```

--------------------------------

### InstructionsRepresentable Protocol Declaration

Source: https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable

Declares the InstructionsRepresentable protocol, which signifies that a type can be represented as instructions. This protocol is available across various Apple platforms starting from iOS 26.0.

```swift
protocol InstructionsRepresentable

```

--------------------------------

### Initialize Instructions

Source: https://developer.apple.com/documentation/foundationmodels/transcript/instructions/init%28id%3Asegments%3Atooldefinitions%3A%29

Initializes instructions for a foundation model, specifying its behavior, segments, and available tools.

```APIDOC
## Initialize Instructions

### Description
Initializes instructions for a foundation model by describing how you want the model to behave using natural language.

### Method
Initializer

### Endpoint
N/A (This is a code-level initialization, not a network endpoint)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
**id** (String) - Optional - A unique identifier for this instructions segment. Defaults to a new UUID.
**segments** (Array<Transcript.Segment>) - Required - An array of segments that make up the instructions.
**toolDefinitions** (Array<Transcript.ToolDefinition>) - Required - Tools that the model should be allowed to call.

### Request Example
```swift
let instructions = Transcript.Instructions(
    id: "my-unique-id",
    segments: [
        // ... array of Transcript.Segment objects
    ],
    toolDefinitions: [
        // ... array of Transcript.ToolDefinition objects
    ]
)
```

### Response
#### Success Response (200)
N/A (This is a code-level initialization, not a network response)

#### Response Example
N/A
```

--------------------------------

### Swift: Implement respond(to:options:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Aoptions%3A%29-b2re

This Swift code snippet demonstrates the signature of the 'respond(to:options:)' instance method for generating text responses from a language model. It takes a String prompt and optional GenerationOptions, returning an asynchronous task that yields a LanguageModelSession.Response.

```swift
@discardableResult nonisolated(nonsending)
final func respond(
    to prompt: String,
    options: GenerationOptions = GenerationOptions()
) async throws -> LanguageModelSession.Response<String>
```

--------------------------------

### asPartiallyGenerated() Instance Method

Source: https://developer.apple.com/documentation/foundationmodels/generable/aspartiallygenerated%28%29

This section details the `asPartiallyGenerated()` instance method, which returns the partially generated type of a struct. It is available across various Apple platforms starting from iOS 26.0.

```APIDOC
## asPartiallyGenerated()

### Description
Returns the partially generated type of this struct.

### Method
Instance Method

### Endpoint
N/A (Instance Method)

### Parameters
None

### Request Example
N/A (Instance Method)

### Response
#### Success Response
- **PartiallyGenerated** (Self.PartiallyGenerated) - The partially generated type of the struct.

#### Response Example
```swift
let partiallyGeneratedObject = myStruct.asPartiallyGenerated()
```

## See Also
### Converting to partially generated
`associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self`
A representation of partially generated content.
**Required** Default implementation provided.
```

--------------------------------

### Access Explanation Stream - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal/explanationstream

Retrieves a stream containing an explanation for why the language model refused to respond. This property is part of the `LanguageModelSession` and is available on multiple Apple platforms starting from version 26.0.

```swift
var explanationStream: LanguageModelSession.ResponseStream<String> { get }
```

--------------------------------

### Get Minimum Value for Array Generation (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/minimum%28_%3A%29

Illustrates the `minimumCount(_:)` static method, which creates a `GenerationGuide` that enforces a minimum number of elements in an array. This is useful for ensuring that generated collections meet a size requirement.

```swift
static func minimumCount<Element>(_ count: Int) -> GenerationGuide<[Element]>
```

--------------------------------

### Prompting for Reasoned Answer Generation (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model

This Swift code snippet shows how to prompt an on-device language model to provide a reasoned answer to a question. It sets up a `LanguageModelSession`, defines instructions that guide the model to show its work and deliver the final answer in a specific field, and then calls the `respond` method to generate the `ReasonableAnswer`.

```swift
let instructions = """
    Answer the person's question.
    1. Begin your response with a plan to solve this question.
    2. Follow your plan's steps and show your work.
    3. Deliver the final answer in `answer`.
    """
var session = LanguageModelSession(instructions: instructions)


// The answer should be 30 days.
let prompt = "How many days are in the month of September?"
let response = try await session.respond(
    to: prompt,
    generating: ReasonableAnswer.self
)

```

--------------------------------

### Generate NPC with LanguageModelSession in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Demonstrates how to use LanguageModelSession to generate an NPC. It involves initializing a session with a system prompt and then constructing a user prompt that includes examples of desired NPC output. The session's respond method is used with the NPC type to generate the character.

```swift
let session = LanguageModelSession {
    """
A conversation between the Player and a helpful assistant. This is a fantasy 
RPG game that takes place at Dream Coffee, the beloved coffee shop of the 
dream realm. Your role is to use your imagination to generate fun game characters.
"""
}
let prompt = """
Create an NPC customer with a fun personality suitable for the dream realm. Have the customer order
coffee. Here are some examples to inspire you:
{name: "Thimblefoot", imageDescription: "A horse with a rainbow mane",
coffeeOrder: "I would like a coffee that's refreshing and sweet like grass of a summer meadow"}
{name: "Spiderkid", imageDescription: "A furry spider with a cool baseball cap",
coffeeOrder: "An iced coffee please, that's as spooky as me!"}
{name: "Wise Fairy", imageDescription: "A blue glowing fairy that radiates wisdom and sparkles",
coffeeOrder: "Something simple and plant-based please, that will restore my wise energy."}
"""


// Generate the NPC using the custom generable type.
let npc = try await session.respond(
    to: prompt,
    generating: NPC.self,
).content
```

--------------------------------

### Arguments Property

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall/arguments

This section details the 'arguments' property, which represents the arguments to be passed to an invoked tool. It is available on iOS, iPadOS, macOS, visionOS, and Mac Catalyst platforms starting from version 26.0.

```APIDOC
## Instance Property: arguments

### Description
Arguments to pass to the invoked tool.

### Availability
iOS 26.0+ iPadOS 26.0+ Mac Catalyst 26.0+ macOS 26.0+ visionOS 26.0+

### Syntax
```swift
var arguments: GeneratedContent { get set }
```

### See Also
#### Inspecting a tool call
`var toolName: String`
The name of the tool being invoked.
```

--------------------------------

### Swift Instance Method: respond(to:schema:includeSchemaInPrompt:options:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Aschema%3Aincludeschemainprompt%3Aoptions%3A%29

This Swift method generates content based on a provided prompt and schema. It allows for controlling schema inclusion and generation options. The method returns a generated content type conforming to the specified schema.

```swift
@discardableResult nonisolated(nonsending)
final func respond(
    to prompt: Prompt,
    schema: GenerationSchema,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
) async throws -> LanguageModelSession.Response<GeneratedContent>
```

--------------------------------

### Swift: Get GenerationGuide for maximumCount

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/maximumcount%28_%3A%29

This snippet shows the static function signature for creating a GenerationGuide that enforces a maximum count for array elements. It's a core part of the FoundationModels framework for controlling generated data structures.

```swift
static func maximumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]
```

--------------------------------

### Create Builder with Second Component - Swift

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither%28second%3A%29

The `buildEither(second:)` static method creates an `Instructions` builder by taking a second component that conforms to `InstructionsRepresentable`. This method is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
static func buildEither(second component: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### Foundation Models - buildOptional(_:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional%28_%3A%29

Creates a builder with an optional component for Foundation Models instructions.

```APIDOC
## static func buildOptional(_: Instructions?)

### Description
Creates a builder with an optional component. This method is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS version 26.0 and later.

### Method
`static func buildOptional(_ instructions: Instructions?) -> Instructions`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
- **instructions** (Instructions) - The constructed Instructions object.

#### Response Example
None
```

--------------------------------

### Initialize LanguageModelFeedback Issue

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/init%28category%3Aexplanation%3A%29

Creates a new issue for language model feedback. This initializer requires a category and optionally accepts an explanation. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
init(
    category: LanguageModelFeedback.Issue.Category,
    explanation: String? = nil
)
```

--------------------------------

### streamResponse(to:schema:includeSchemaInPrompt:options:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28to%3Aschema%3Aincludeschemainprompt%3Aoptions%3A%29

This method produces a stream of responses from a language model, guided by a prompt and a specified schema for structured output. It allows for control over schema inclusion and generation options.

```APIDOC
## POST /websites/developer_apple_foundationmodels/streamResponse

### Description
Produces a response stream to a prompt and schema. This method is suitable for iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/streamResponse`

### Parameters
#### Request Body
- **prompt** (Prompt) - Required - A prompt for the model to respond to.
- **schema** (GenerationSchema) - Required - A schema to guide the output with.
- **includeSchemaInPrompt** (Bool) - Optional - Defaults to `true`. Inject the schema into the prompt to bias the model. Consider using the default value unless the model has prior knowledge of the expected response format.
- **options** (GenerationOptions) - Optional - Options that control how tokens are sampled from the distribution the model produces.

### Request Example
```json
{
  "prompt": {
    "text": "Generate a JSON object representing a user profile."
  },
  "schema": {
    "type": "object",
    "properties": {
      "name": {"type": "string"},
      "age": {"type": "integer"}
    }
  },
  "includeSchemaInPrompt": true,
  "options": {
    "temperature": 0.7,
    "maxTokens": 100
  }
}
```

### Response
#### Success Response (200)
- **ResponseStream<GeneratedContent>** - A response stream that produces `GeneratedContent` containing the fields and values defined in the schema.

#### Response Example
```json
{
  "content": {
    "name": "John Doe",
    "age": 30
  }
}
```

### Discussion
Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

**Important:** If running in the background, use the non-streaming `respond(to:options:)` method to reduce the likelihood of encountering `LanguageModelSession.GenerationError.rateLimited(_:)` errors.

### See Also
- `streamResponse(to:options:)`
- `streamResponse(to:generating:includeSchemaInPrompt:options:)`
- `streamResponse(options: GenerationOptions, prompt: () throws -> Prompt)`
- `streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt)`
- `streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt)`
- `struct ResponseStream`
- `struct GeneratedContent`
- `protocol ConvertibleFromGeneratedContent`
- `protocol ConvertibleToGeneratedContent`
```

--------------------------------

### GeneratedContent Initializer

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28kind%3Aid%3A%29

Initializes a new `GeneratedContent` instance with a specified kind and an optional `GenerationID`.

```APIDOC
## Initializer: GeneratedContent

### Description
Creates a new `GeneratedContent` instance with the specified kind and `GenerationID`.

### Method
`init(kind: GeneratedContent.Kind, id: GenerationID? = nil)`

### Parameters

#### Path Parameters
None

#### Query Parameters
None

#### Request Body

- **kind** (GeneratedContent.Kind) - Required - The kind of content to create.
- **id** (GenerationID?) - Optional - An optional `GenerationID` to associate with this content.

### Request Example
```swift
let newContent = GeneratedContent(kind: .text, id: GenerationID("my-custom-id"))
```

### Response
#### Success Response (200)
N/A - This is an initializer, not an endpoint that returns data.

#### Response Example
N/A
```

--------------------------------

### LanguageModelFeedback.Sentiment.negative

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment/negative

Describes the negative sentiment case within the LanguageModelFeedback API. This indicates a negative sentiment detected by the language model. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```APIDOC
## LanguageModelFeedback.Sentiment.negative

### Description
A negative sentiment as detected by the language model.

### Method
N/A (This is a case definition, not an API endpoint)

### Endpoint
N/A

### Parameters
N/A

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
```swift
case negative
```

### Platform Availability
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+
```

--------------------------------

### Generate structured data with Foundation Models

Source: https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models

Defines a `CatProfile` struct annotated with `@Generable` and `@Guide` for structured data generation. The `LanguageModelSession().respond` method is used to generate an instance of this struct based on a prompt. This demonstrates how to define inputs and expected outputs for the model.

```swift
@Generable(description: "Basic profile information about a cat")
struct CatProfile {
    var name: String


    @Guide(description: "The age of the cat", .range(0...20))
    var age: Int


    @Guide(description: "One sentence about this cat's personality")
    var profile: String
}


#Playground {
    let response = try await LanguageModelSession().respond(
        to: "Generate a rescue cat",
        generating: CatProfile.self
    )
}
```

--------------------------------

### Accessing Prompt Identifier (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/id

Retrieves the unique identifier for a prompt within the Transcript.Prompt class. This property is a String and is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
var id: String
```

--------------------------------

### Instance Method: respond(generating:includeSchemaInPrompt:options:prompt:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28generating%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

Produces a generable object as a response to a prompt, allowing for fine-grained control over content generation and schema inclusion.

```APIDOC
## respond(generating:includeSchemaInPrompt:options:prompt:)

### Description
Produces a generable object as a response to a prompt.

### Method
`final func respond<Content>(generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>` where Content : Generable

### Parameters
#### Generics
- **Content** (Type) - A type to produce as the response.

#### Path Parameters
* **type** (Type) - Required - A type to produce as the response.
* **includeSchemaInPrompt** (Bool) - Optional - Inject the schema into the prompt to bias the model. Defaults to `true`.
* **options** (GenerationOptions) - Optional - Options that control how tokens are sampled from the distribution the model produces. Defaults to `GenerationOptions()`.
* **prompt** (PromptBuilder) - Required - A prompt for the model to respond to.

### Return Value
`LanguageModelSession.Response<Content>` containing the fields and values defined in the schema.

### Discussion
Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

### See Also
* `func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>`
* `func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>`
* `func respond(to:options:)`
* `func respond(to:generating:includeSchemaInPrompt:options:)`
* `func respond(to:schema:includeSchemaInPrompt:options:)`
* `struct Prompt`
* `struct Response`
* `struct GenerationOptions`
```

--------------------------------

### Define CalendarTool Description

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Provides a description for the CalendarTool, explaining its purpose to the model. This description includes the contact name and the current date, guiding the model on how to utilize the tool for fetching calendar events.

```swift
description = """
    Get an event from the player's calendar with (contactName). \ 
    Today is (Date().formatted(date: .complete, time: .omitted))
    """

```

--------------------------------

### Define PromptBuilder Struct in Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder

Defines the PromptBuilder struct, a result builder used for constructing prompts. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
@resultBuilder
struct PromptBuilder
```

--------------------------------

### Initialize Foundation Model with a Tool

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition/init%28tool%3A%29

This initializer creates a Foundation Model instance using a provided `Tool` object. It is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0. The initializer takes a single argument of type `some Tool`.

```swift
init(tool: some Tool)
```

--------------------------------

### Build Either Prompt (Second Component) - Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28second%3A%29

Creates a prompt builder that includes the second component of a choice. This function is part of the Swift build system for constructing complex prompts from simpler representable types. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
static func buildEither(second component: some PromptRepresentable) -> Prompt
```

--------------------------------

### Create Constant String Generation Guide

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/constant%28_%3A%29

This static method creates a `GenerationGuide` that enforces a string value to be exactly equal to the provided `value` parameter. It's useful for ensuring specific string outputs in generative models. This functionality is available when the expected `Value` type is `String`.

```swift
static func constant(_ value: String) -> GenerationGuide<String>
```

--------------------------------

### Initialize Instance from Generated Content (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/convertiblefromgeneratedcontent/init%28_%3A%29

Demonstrates how to manually initialize a Swift struct that conforms to `ConvertibleFromGeneratedContent`. This method decodes values from a `GeneratedContent` object using specified property names, allowing for flexible mapping of model outputs to struct properties.

```swift
struct Person: ConvertibleFromGeneratedContent {
    var name: String
    var age: Int


    init(_ content: GeneratedContent) {
        self.name = try content.value(forProperty: "firstName")
        self.age = try content.value(forProperty: "ageInYears")
    }
}
```

--------------------------------

### Create Dialog Instructions for Character - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Constructs specific instructions for a LanguageModelSession to manage multi-turn conversations. It defines the character's display name, persona, and initial dialogue to guide the AI's responses and maintain character consistency within the game.

```swift
let instructions = """
A multiturn conversation between a game character and the player of this game. \ 
    You are (character.displayName). Refer to (character.displayName) in the first-person \ 
    (like "I" or "me"). You must respond in the voice of (character.persona).

    Keep your responses short and positive. Remember: Because this is the dream realm, \ 
    everything is free at this coffee shop and the baristas are paid in creative inpiration.

    You just said: "\(startWith)"
    """

```

--------------------------------

### Transcript.Segment.text(_:)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/segment/text%28_%3A%29

This section details the `text(_:)` case of the `Transcript.Segment` enum, which represents a segment containing text data. It is available on iOS, iPadOS, macOS, Mac Catalyst, and visionOS starting from version 26.0.

```APIDOC
## Transcript.Segment.text(_:)

### Description
A segment containing text data.

### Method
Enum Case

### Endpoint
N/A (Enum Case)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
```swift
case text(Transcript.TextSegment)
```

### Response
#### Success Response (200)
N/A (Enum Case)

#### Response Example
N/A (Enum Case)

## See Also
### Creating a segment
`case structure(Transcript.StructuredSegment)`
A segment containing structured content.

```

--------------------------------

### Instance Property: instructionsRepresentation

Source: https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation-57k7v

Retrieves an instance that represents the instructions for Foundation Models.

```APIDOC
## Instance Property: instructionsRepresentation

### Description
An instance that represents the instructions.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels

### Parameters
None

### Request Example
None

### Response
#### Success Response (200)
- **instructionsRepresentation** (Instructions) - An object representing the instructions.

#### Response Example
```json
{
  "instructionsRepresentation": {
    "instruction1": "value1",
    "instruction2": "value2"
  }
}
```
```

--------------------------------

### Initialize Property with Dynamic Schema (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/property/init%28name%3Adescription%3Aschema%3Aisoptional%3A%29

Creates a property referencing a dynamic schema. This initializer is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0. It requires a name, a schema, and optionally accepts a description and a boolean to indicate if the property is optional.

```swift
init(
    name: String,
    description: String? = nil,
    schema: DynamicGenerationSchema,
    isOptional: Bool = false
)
```

--------------------------------

### Get Debug Description for Foundation Models (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/debugdescription

Retrieves a string representation of a Foundation Model instance for debugging purposes. This property is available from iOS, iPadOS, macOS, Mac Catalyst, and visionOS version 26.0 and later.

```swift
var debugDescription: String { get }
```

--------------------------------

### Prompt Initializer

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/init%28id%3Asegments%3Aoptions%3Aresponseformat%3A%29

This section describes the initializer used to create a prompt for the Foundation Models API. It outlines the parameters required for setting up a new prompt, including its unique identifier, the segments that form its content, generation options, and the desired response format.

```APIDOC
## init(id:segments:options:responseFormat:)

### Description
Creates a prompt with specified segments, options, and an optional response format.

### Method
Initializer

### Endpoint
N/A (This is an initializer, not a REST endpoint)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **id** (String) - Optional - A unique identifier for the prompt. Defaults to a new UUID.
- **segments** (Array<Transcript.Segment>) - Required - An array of segments that constitute the prompt.
- **options** (GenerationOptions) - Optional - Options to control token sampling and generation. Defaults to `GenerationOptions()`.
- **responseFormat** (Transcript.ResponseFormat?) - Optional - Specifies the desired structure for the response.

### Request Example
```swift
let prompt = FoundationModels.Transcript.init(
    segments: [
        .text("Hello, "),
        .text("world!")
    ],
    options: GenerationOptions(temperature: 0.7)
)
```

### Response
#### Success Response (200)
N/A (Initializers do not return HTTP responses; they construct objects in memory.)

#### Response Example
N/A
```

--------------------------------

### Defining a Generable Structure for Customer Data (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model

This Swift code defines a struct `NPC` marked with `@Generable` for guided generation. This structure dictates the expected fields (`name`, `coffeeOrder`, `imageDescription`) for the model's output, ensuring structured and consistent responses.

```swift
@Generable
struct NPC: Equatable {
    let name: String
    let coffeeOrder: String
    let imageDescription: String
}

```

--------------------------------

### Configure Foundation Model Instructions with init(_:)

Source: https://developer.apple.com/documentation/foundationmodels/instructions/init%28_%3A%29

The init(_:) initializer is used to configure instructions for Foundation Models. It accepts a closure that returns `Instructions` and is available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

```swift
init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows
```

--------------------------------

### Create Generation Schema with Properties

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/init%28type%3Adescription%3Aproperties%3A%29

Initializes a generation schema by specifying its type, an optional description, and an array of properties. This is useful for defining structured data schemas.

```swift
init(
    type: any Generable.Type,
    description: String? = nil,
    properties: [GenerationSchema.Property]
)
```

--------------------------------

### Access toolName Instance Property - Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall/toolname

The `toolName` instance property returns the name of the tool being invoked. This property is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
var toolName: String
```

--------------------------------

### Accessing Generated Content Instance Property

Source: https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent/generatedcontent

This snippet shows how to access the `generatedContent` instance property, which represents data as generated content. It is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
var generatedContent: GeneratedContent { get }
```

--------------------------------

### Swift: StructuredSegment Structure Definition

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment

Defines the `StructuredSegment` structure, which represents a segment containing structured data within a transcript. It is available on iOS, iPadOS, macOS, and visionOS platforms starting from version 26.0.

```swift
struct StructuredSegment
```

--------------------------------

### Create SystemLanguageModel Instance with Custom Adapter

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Creates an instance of `SystemLanguageModel` using a previously initialized adapter. This specialized model can then be used to create a language model session for generating responses.

```swift
// An instance of the the system language model using your adapter.
let customAdapterModel = SystemLanguageModel(adapter: adapter)


// Create a session and prompt the model.
let session = LanguageModelSession(model: customAdapterModel)
let response = try await session.respond(to: "Your prompt here")
```

--------------------------------

### Swift: Build Instruction Array

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional%28_%3A%29

The `buildArray(_:)` static method creates an `Instructions` builder from an array of prompts. This allows for constructing instruction sequences where multiple prompts are provided in a collection. It accepts an array of `InstructionsRepresentable` items and returns an `Instructions` object.

```swift
static func buildArray([some InstructionsRepresentable]) -> Instructions
```

--------------------------------

### Define Dynamic Schema at Runtime with Foundation Models (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation

This snippet demonstrates how to create a dynamic schema at runtime using `DynamicGenerationSchema`. This is useful when the model's output structure depends on variable inputs, such as a restaurant's menu options. It defines properties and their possible values.

```swift
let menuSchema = DynamicGenerationSchema(
    name: "Menu",
    properties: [
        DynamicGenerationSchema.Property(
            name: "dailySoup",
            schema: DynamicGenerationSchema(
                name: "dailySoup",
                anyOf: ["Tomato", "Chicken Noodle", "Clam Chowder"]
            )
        )
        // Add additional properties.
    ]
)
```

--------------------------------

### Initialize Instructions: Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/instructions/init%28id%3Asegments%3Atooldefinitions%3A%29

Initializes instructions for a foundation model. It requires an array of `Transcript.Segment` objects and an array of `Transcript.ToolDefinition` objects. An optional `id` can be provided; otherwise, a UUID string is generated.

```swift
init(
    id: String = UUID().uuidString,
    segments: [Transcript.Segment],
    toolDefinitions: [Transcript.ToolDefinition]
)
```

--------------------------------

### GeneratedContent.Kind Swift Case Definitions

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift

These Swift code examples illustrate the various cases within the GeneratedContent.Kind enumeration. Each case represents a specific type of generated content, such as an array of GeneratedContent, a boolean, a null value, a numeric value, a string, or a structured object with properties.

```swift
case array([GeneratedContent])
case bool(Bool)
case null
case number(Double)
case string(String)
case structure(properties: [String : GeneratedContent], orderedKeys: [String])
```

--------------------------------

### Initialize Generation Options - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/init%28sampling%3Atemperature%3Amaximumresponsetokens%3A%29

Creates generation options that control token sampling behavior. It takes optional parameters for sampling strategy, temperature, and maximum response tokens. Temperature must be between 0 and 1, and maximumResponseTokens must be positive.

```swift
init(
    sampling: GenerationOptions.SamplingMode? = nil,
    temperature: Double? = nil,
    maximumResponseTokens: Int? = nil
)
```

--------------------------------

### Log Feedback Attachment (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredresponsetext%3A%29

Logs and serializes data including session information when reporting feedback to Apple. This method is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
@backDeployed(before: iOS 26.1, macOS 26.1, visionOS 26.1)
@discardableResult
final func logFeedbackAttachment(
    sentiment: LanguageModelFeedback.Sentiment?,
    issues: [LanguageModelFeedback.Issue] = [],
    desiredResponseText: String?
) -> Data
```

--------------------------------

### POST /languageModelSession/respond

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Aoptions%3A%29-6a2gb

Initiates a request to the foundation model to generate a text response based on a given prompt and customizable generation options.

```APIDOC
## POST /languageModelSession/respond

### Description
Produces a response to a prompt using the foundation model.

### Method
POST

### Endpoint
/languageModelSession/respond

### Parameters
#### Request Body
- **prompt** (Prompt) - Required - A prompt for the model to respond to.
- **options** (GenerationOptions) - Optional - GenerationOptions that control how tokens are sampled from the distribution the model produces. Defaults to an empty GenerationOptions object.

### Request Example
```json
{
  "prompt": "What is the capital of France?",
  "options": {
    "temperature": 0.7,
    "maxTokens": 100
  }
}
```

### Response
#### Success Response (200)
- **response** (LanguageModelSession.Response<String>) - A string composed of the tokens produced by sampling model output.

#### Response Example
```json
{
  "response": "The capital of France is Paris."
}
```
```

--------------------------------

### Create a Prompt from a String Literal

Source: https://developer.apple.com/documentation/foundationmodels/prompt

This snippet demonstrates how to initialize a Prompt object using a simple string literal. This is the most straightforward way to create a prompt when the content is static.

```swift
let prompt = Prompt("What are miniature schnauzers known for?")
```

--------------------------------

### PromptBuilder API

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildoptional%28_%3A%29

This section details the methods available for building prompts using the PromptBuilder.

```APIDOC
## buildOptional(_:)

### Description
Creates a builder with an optional component.

### Method
`static func buildOptional(_ component: Prompt?) -> Prompt`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
- **Prompt** (Prompt) - The built prompt with an optional component.

#### Response Example
```json
{
  "prompt": "Your optional prompt content"
}
```

## See Also

### Building a prompt

- `static func buildArray([some PromptRepresentable]) -> Prompt`
  Creates a builder with the an array of prompts.
- `static func buildBlock<each P>(repeat each P) -> Prompt`
  Creates a builder with the a block.
- `static func buildEither(first: some PromptRepresentable) -> Prompt`
  Creates a builder with the first component.
- `static func buildEither(second: some PromptRepresentable) -> Prompt`
  Creates a builder with the second component.
- `buildExpression(_:)`
  Creates a builder with a prompt expression.
- `static func buildLimitedAvailability(some PromptRepresentable) -> Prompt`
  Creates a builder with a limited availability prompt.
```

--------------------------------

### Respond to Prompt with Generable Content (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Agenerating%3Aincludeschemainprompt%3Aoptions%3A%29

This Swift code snippet shows how to use the `respond` method to get a generable object response from a language model. It takes a `Prompt`, optionally specifies the generation `type`, `includeSchemaInPrompt` boolean, and `options`. It returns a `LanguageModelSession.Response` of the specified `Generable` type.

```swift
@discardableResult nonisolated(nonsending)
final func respond<Content>(
    to prompt: Prompt,
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
) async throws -> LanguageModelSession.Response<Content> where Content : Generable
```

--------------------------------

### Initialize Response Format with Generable Type (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/responseformat/init%28type%3A%29

Creates a response format using a specified `Generable` type. This initializer requires the `Content` type to conform to the `Generable` protocol. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
init<Content>(type: Content.Type) where Content : Generable
```

--------------------------------

### Initialize GenerationSchema.SchemaError.Context with Debug Description (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/context/init%28debugdescription%3A%29

This code snippet shows how to initialize the GenerationSchema.SchemaError.Context object using its designated initializer, which accepts a `debugDescription` string. This initializer is available across multiple Apple platforms including iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
init(debugDescription: String)
```

--------------------------------

### SystemLanguageModel.Adapter - Loading the model with an adapter

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter

Details on how to load the base system language model with a custom adapter, allowing for specialized behavior.

```APIDOC
### Loading the model with an adapter

Specialize the behavior of the system language model by using a custom adapter you train.

#### Permissions

- **com.apple.developer.foundation-model-adapter** (Boolean) - A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

#### Initializers

- **`convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)`**

Creates the base version of the model with an adapter.
```

--------------------------------

### Instruct Model Behavior for Sensitive Content (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

Uses session instructions to guide the model's handling of sensitive content, prioritizing these instructions over prompts for improved safety and generation quality. Emphasizes key directives using uppercase.

```swift
do {
    let instructions = """
        ALWAYS respond in a respectful way. \ 
        If someone asks you to generate content that might be sensitive, \ 
        you MUST decline with 'Sorry, I can't do that.'
        """
    let session = LanguageModelSession(instructions: instructions)
    let prompt = // Open input from a person using the app.
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.guardrailViolation {
    // Handle the safety error.
}

```

--------------------------------

### Access creatorDefinedMetadata from SystemLanguageModel.Adapter

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/creatordefinedmetadata

This code snippet shows how to access the `creatorDefinedMetadata` property of a `SystemLanguageModel.Adapter` instance. This property returns a dictionary containing key-value pairs defined by the creator of the adapter's metadata. It is available on multiple Apple platforms starting with OS version 26.0.

```swift
var creatorDefinedMetadata: [String : Any] { get }
```

--------------------------------

### Create New Session with Transcript Context

Source: https://developer.apple.com/documentation/foundationmodels/transcript

Provides a Swift function `newContextualSession` that creates a new `LanguageModelSession` initialized with specific entries from an existing session's transcript. This allows for re-establishing a contextual session, for example, by including only the first and last entries to maintain a degree of continuity.

```swift
// Create a new session with the first and last entries from a previous session.
func newContextualSession(with originalSession: LanguageModelSession) -> LanguageModelSession {
    let allEntries = originalSession.transcript


    // Collect the entries to keep from the original session.
    let entries = [allEntries.first, allEntries.last].compactMap { $0 }
    let transcript = Transcript(entries: entries)


    // Create a new session with the result and preload the session resources.
    var session = LanguageModelSession(transcript: transcript)
    session.prewarm()
    return session
}
```

--------------------------------

### Stream Response to Prompt - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28options%3Aprompt%3A%29

This Swift code snippet demonstrates how to use the `streamResponse(options:prompt:)` method to get a stream of string responses from a language model. It utilizes a `PromptBuilder` for constructing the prompt and returns a `LanguageModelSession.ResponseStream<String>`.

```swift
final func streamResponse(
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
) rethrows -> sending LanguageModelSession.ResponseStream<String>
```

--------------------------------

### Create Adapter with Name (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/init%28name%3A%29

Initializes an adapter for Foundation Models by specifying its name, which is downloaded from the background assets framework. This initializer may throw an `AssetLoadingError` if no compatible asset packs are found.

```swift
init(name: String) throws
```

--------------------------------

### Initialize Foundation Model with Source and Content

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment/init%28id%3Asource%3Acontent%3A%29

Initializes a Foundation Model instance with a unique identifier, source string, and generated content. The identifier defaults to a new UUID string if not provided. This initializer is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
init(
    id: String = UUID().uuidString,
    source: String,
    content: GeneratedContent
)
```

--------------------------------

### Generable.PartiallyGenerated Type Alias

Source: https://developer.apple.com/documentation/foundationmodels/generable/partiallygenerated-swift

This section details the `PartiallyGenerated` type alias, which is a representation of content that has been partially generated. It is available on iOS, iPadOS, macOS, Mac Catalyst, and visionOS starting from version 26.0.

```APIDOC
## Generable.PartiallyGenerated

### Description
A representation of partially generated content.

### Supported Platforms
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+

### Type Alias Definition
```swift
typealias PartiallyGenerated = Self
```
```

--------------------------------

### Building Instructions with Either Component (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildlimitedavailability%28_%3A%29

These Swift methods create an `Instructions` builder by selecting one of two possible components. They allow for conditional instruction presentation based on which overload is called, taking either the 'first' or 'second' `InstructionsRepresentable` argument.

```swift
static func buildEither(first: some InstructionsRepresentable) -> Instructions
```

```swift
static func buildEither(second: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### Access Transcript Entries in Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/transcriptentries

This Swift code snippet demonstrates how to access the list of transcript entries. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0. The property returns an ArraySlice of Transcript.Entry objects.

```swift
let transcriptEntries: ArraySlice<Transcript.Entry>
```

--------------------------------

### Get JSON String Representation of Generated Content (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/jsonstring

The `jsonString` property returns a JSON string representation of the generated content. This is useful for serializing and debugging content objects. It requires no specific inputs and outputs a string.

```swift
var jsonString: String { get }
```

```swift
// Object with properties
let content = GeneratedContent(properties: [
    "name": "Johnny Appleseed",
    "age": 30,
])
print(content.jsonString)
// Output: {"name": "Johnny Appleseed", "age": 30}
```

--------------------------------

### Get recoverySuggestion - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/recoverysuggestion

Retrieves a string suggesting how to handle an error related to Foundation Models. This property is read-only and returns an optional String. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS version 26.0 and later.

```swift
var recoverySuggestion: String? { get }
```

--------------------------------

### Swift: LanguageModelSession.Response Structure Definition

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response

Defines the LanguageModelSession.Response structure, which holds the output of a response call. It is generic over a Content type that must conform to the Generable protocol. Available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
struct Response<Content> where Content : Generable

```

--------------------------------

### Swift: LanguageModelSession.GenerationError.Context Structure

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/context

Represents the context in which a generation error occurred within a LanguageModelSession. It contains a debug description to aid in diagnosing issues during development. Available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
struct Context {
    let debugDescription: String
}
```

--------------------------------

### Create Prompt Builder Methods (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildlimitedavailability%28_%3A%29

This section outlines various methods for constructing prompts using builders. These include creating prompts from arrays, blocks, conditional components (either first or second), expressions, and optional components. These methods are fundamental for assembling complex prompts in Swift.

```swift
static func buildArray([some PromptRepresentable]) -> Prompt
```

```swift
static func buildBlock<each P>(repeat each P) -> Prompt
```

```swift
static func buildEither(first: some PromptRepresentable) -> Prompt
```

```swift
static func buildEither(second: some PromptRepresentable) -> Prompt
```

```swift
static buildExpression(_:)
```

```swift
static func buildOptional(Prompt?) -> Prompt
```

--------------------------------

### Define a Prompt Entry for Transcript

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/prompt%28_%3A%29

This code snippet demonstrates how to define a prompt entry using the `prompt(_:)` case within the `Transcript.Entry` enum. This case is used to represent user-initiated prompts in conversational AI or transcript logging. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
case prompt(Transcript.Prompt)
```

--------------------------------

### Building Instructions with Optional Components (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildlimitedavailability%28_%3A%29

This Swift method creates an `Instructions` builder that may include an optional component. It takes a single optional `Instructions` value, allowing for instructions that might or might not be present.

```swift
static func buildOptional(Instructions?) -> Instructions
```

--------------------------------

### Get Response Generation Status (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/isresponding

This Swift code snippet shows the declaration of the `isResponding` property, which is a read-only Boolean indicating whether a response is currently being generated by the model. This property is essential for managing the state of model interactions.

```swift
final var isResponding: Bool { get }
```

--------------------------------

### Enforce Array Count with GenerationGuide

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/count%28_%3A%29

The `count(_:)` method is a static function that returns a `GenerationGuide`. This guide enforces that a generated array must contain exactly a specified number of elements. It's often used to validate or structure array outputs from generative models, such as ensuring a list of items has a fixed size.

```swift
static func count<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]
```

```swift
@Generable
struct struct Shop {
    @Guide(description: "A creative name for a shop in a fantasy RPG")
    var name: String


    @Guide(description: "A list of items for sale", .count(3))
    var inventory: [ShopItem]
}
```

--------------------------------

### Access Foundation Models Debug Description (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/context/debugdescription

Retrieves a string representation of the debug description for Foundation Models. This property is intended for debugging and should not be displayed to end users as it is not localized. It is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
let debugDescription: String
```

--------------------------------

### Initialize Foundation Model with ID, Tool Name, and Arguments

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall/init%28id%3Atoolname%3Aarguments%3A%29

This initializer sets up a Foundation Model instance using a unique identifier, the name of the associated tool, and specific arguments. It is crucial for configuring the model's behavior and its interaction with tools. Availability starts from iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, and visionOS 26.0.

```swift
init(
    id: String,
    toolName: String,
    arguments: GeneratedContent
)
```

--------------------------------

### Building Instructions from Expressions (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildlimitedavailability%28_%3A%29

This Swift method constructs an `Instructions` builder directly from an expression. It's designed to handle single prompt expressions within the instruction building process.

```swift
buildExpression(_:)
```

--------------------------------

### Swift Case: triggeredGuardrailUnexpectedly

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/triggeredguardrailunexpectedly

Represents a scenario where the language model incorrectly triggers a guardrail violation. This case is part of the `LanguageModelFeedback.Issue.Category` enum and is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
case triggeredGuardrailUnexpectedly
```

--------------------------------

### Enforce Minimum Value with GenerationGuide (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/minimum%28_%3A%29

Demonstrates how to use the `minimum(_:)` method to enforce a minimum value for a `GenerationGuide`. This is useful for ensuring generated data meets certain criteria, such as a minimum level for a game character.

```swift
@Generable
struct GameCharacter {
    @Guide(description: "A creative name appropriate for a fantasy RPG character")
    var name: String

    @Guide(description: "A level for the character", .minimum(1))
    var level: Int
}
```

--------------------------------

### Set Model Output Language with Session Instructions (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models

This Swift code demonstrates how to explicitly set the model's output language using `LanguageModelSession`. It initializes a session with specific instructions, such as 'You MUST respond in U.S. English.', and then sends a prompt to the session to get a response. This is useful when dealing with apps that support multiple languages or when inputs vary in language.

```swift
let session = LanguageModelSession(
    instructions: "You MUST respond in U.S. English."
)
let prompt = // A prompt that contains Spanish and Italian.
let response = try await session.respond(to: prompt)

```

--------------------------------

### Swift: Accessing Tool Definitions in Transcripts

Source: https://developer.apple.com/documentation/foundationmodels/transcript/instructions/tooldefinitions

This snippet demonstrates how to access the `toolDefinitions` property, which is an array of `Transcript.ToolDefinition` objects. This property is available on iOS, iPadOS, macOS, Mac Catalyst, and visionOS starting from version 26.0. It allows developers to understand the tools provided to the model.

```swift
var toolDefinitions: [Transcript.ToolDefinition]
```

--------------------------------

### SystemLanguageModel.Adapter - Creating an adapter

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter

This section details how to create a custom adapter for the system language model. You can create an adapter from a file URL or download one from the background assets framework.

```APIDOC
## SystemLanguageModel.Adapter

Specializes the system language model for custom use cases.

### Creating an adapter

Specialize the behavior of the system language model by using a custom adapter you train.

#### Permissions

- **com.apple.developer.foundation-model-adapter** (Boolean) - Indicates whether the app can enable custom adapters for the Foundation Models framework.

#### Initializers

- **`init(fileURL: URL) throws`**
  Creates an adapter from the file URL.
- **`init(name: String) throws`**
  Creates an adapter downloaded from the background assets framework.
```

--------------------------------

### Get Compatible Adapter Identifiers (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/compatibleadapteridentifiers%28name%3A%29

This method returns all adapter identifiers compatible with the current system models, sorted by system preference. It takes the adapter's name as input and returns an array of strings representing the compatible identifiers. The result is guaranteed to be non-empty on devices supporting Apple Intelligence.

```swift
static func compatibleAdapterIdentifiers(name: String) -> [String]
```

--------------------------------

### Tool Definition - Name Property

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition/name

Provides details about the 'name' property for a tool definition within the Foundation Models API. This property represents the tool's name and is available on iOS, iPadOS, macOS, visionOS, and Mac Catalyst starting from version 26.0.

```APIDOC
## Instance Property: name

### Description
The tool’s name.

### Availability
iOS 26.0+ 
iPadOS 26.0+ 
Mac Catalyst 26.0+ 
macOS 26.0+ 
visionOS 26.0+

### Syntax
```swift
var name: String
```

### See Also
#### Inspecting a tool definition
- `var description: String`
A description of how and when to use the tool.

Current page is name
```

--------------------------------

### Swift: LanguageModelFeedback.Issue.Category.didNotFollowInstructions

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/didnotfollowinstructions

This Swift code snippet defines the 'didNotFollowInstructions' case for the LanguageModelFeedback.Issue.Category enum. This case is used to report when a language model fails to follow the provided instructions. It is available on multiple Apple platforms starting from version 26.0.

```swift
case didNotFollowInstructions
```

--------------------------------

### Crafting Prompts for Model Responses

Source: https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models

Demonstrates how to create different types of prompts for foundation models. One prompt is designed for a longer, more detailed response, while the other aims for a quick, concise output by specifying generation constraints.

```swift
// Generate a longer response for a specific command.
let simple = "Write me a story about pears."


// Quickly generate a concise response.
let quick = "Write the profile for the dog breed Siberian Husky using three sentences."
```

--------------------------------

### Accessing Response Content (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/content

This snippet demonstrates how to access the 'content' property of a Foundation Model response. 'content' represents the partially generated response, and its type is 'Content.PartiallyGenerated'. This property is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
var content: Content.PartiallyGenerated

```

--------------------------------

### Swift: Define struct with maximumCount for array property

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/maximumcount%28_%3A%29

Demonstrates how to use the @Guide and .maximumCount modifier to limit the number of elements in an array property within a struct. This ensures the generated data adheres to a specified size constraint, useful for scenarios like limiting shop inventory.

```swift
@Generable
struct struct Shop {
    @Guide(description: "A creative name for a shop in a fantasy RPG")
    var name: String


    @Guide(description: "A list of items for sale", .maximumCount(10))
    var inventory: [ShopItem]
}
```

--------------------------------

### Declare Neutral Sentiment Case - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment/neutral

This code snippet demonstrates how to declare the neutral sentiment case. This is a fundamental part of defining sentiment values for feedback in models. It is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
case neutral
```

--------------------------------

### Create Generated Content from Sequence with Uniquing Keys

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28properties%3Aid%3A%29

Creates new generated content from a sequence of key-value pairs, using a provided closure to resolve values for duplicate keys. This initializer is useful for creating content from various data structures.

```swift
init<S>(properties: S, id: GenerationID?, uniquingKeysWith: (GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent) rethrows
```

--------------------------------

### Read Typed Value by Property Name (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/value%28_%3Aforproperty%3A%29-3xsez

This Swift method retrieves a specific typed value for a given property name. It requires the value type to conform to `ConvertibleFromGeneratedContent`. It is available on iOS, iPadOS, macOS, and visionOS starting from version 26.0.

```swift
func value<Value>(
    _ type: Value.Type = Value.self,
    forProperty property: String
) throws -> Value where Value : ConvertibleFromGeneratedContent
```

--------------------------------

### Building Instructions with Conditionals and Optionals

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder

Details how `InstructionsBuilder` handles conditional logic (either-or) and optional components when constructing `Instructions`. This allows for dynamic instruction generation.

```swift
static func buildEither(first: some InstructionsRepresentable) -> Instructions
static func buildEither(second: some InstructionsRepresentable) -> Instructions
static func buildOptional(_: Instructions?) -> Instructions
```

--------------------------------

### Get Asset Identifiers (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/response/assetids

Retrieves version-aware identifiers for all assets used to generate a response from Apple's Foundation Models. This property is available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

```swift
var assetIDs: [String]
```

--------------------------------

### Create Content from JSON String (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28json%3A%29

Initializes equivalent content from a JSON string. This initializer is useful for handling partially generated responses as the provided JSON string may be incomplete. It requires a valid JSON string as input and can throw an error if the JSON is malformed.

```swift
@Generable struct NovelIdea {
  let title: String
}


let partial = #"{"title": "A story of"#
let content = try GeneratedContent(json: partial)
let idea = try NovelIdea(content)
print(idea.title) // A story of
```

--------------------------------

### Initialize Transcript Tool Calls with ID and Sequence

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcalls/init%28id%3A_%3A%29

Initializes a new instance of `Transcript.ToolCalls` with a unique identifier and a sequence of tool calls. The `id` parameter defaults to a new UUID string if not provided. The `calls` parameter accepts any sequence of `Transcript.ToolCall` elements. This initializer is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
init<S>(
    id: String = UUID().uuidString,
    _ calls: S
) where S : Sequence, S.Element == Transcript.ToolCall
```

--------------------------------

### Initialize Foundation Model Prompt with PromptBuilder

Source: https://developer.apple.com/documentation/foundationmodels/prompt/init%28_%3A%29

This initializer constructs a Foundation Model prompt using a closure that returns a Prompt. It supports Swift and is available on iOS, iPadOS, macOS, and visionOS versions 26.0 and later. The initializer can throw errors.

```swift
init(@PromptBuilder _ content: () throws -> Prompt) rethrows
```

--------------------------------

### Create Builder with First Component (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither%28first%3A%29

This method creates an `Instructions` builder by accepting the first component of a set of instructions. It is part of the `InstructionsBuilder` functionality for creating complex instruction sequences. This function is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS from version 26.0 onwards.

```swift
static func buildEither(first component: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### Initialize SystemLanguageModel with Adapter and Guardrails

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/init%28adapter%3Aguardrails%3A%29

Creates an instance of SystemLanguageModel using a provided adapter and optional guardrails. The default guardrails are used if none are specified. This initializer is essential for customizing the model's behavior with a trained adapter.

```swift
convenience init(
    adapter: SystemLanguageModel.Adapter,
    guardrails: SystemLanguageModel.Guardrails = .default
)
```

--------------------------------

### Initialize Transcript Segment with ID, Tool Name, and Segments

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooloutput/init%28id%3Atoolname%3Asegments%3A%29

This initializer sets up a new `Transcript.Segment` object. It requires a unique identifier string, the name of the tool used, and an array of `Transcript.Segment` objects. This is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
init(
    id: String,
    toolName: String,
    segments: [Transcript.Segment]
)
```

--------------------------------

### Initialize Session with Tools (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling

Initializes a LanguageModelSession with a list of tools that the model can call. These tools are then available for all future interactions within that session.

```swift
let session = LanguageModelSession(
    tools: [BreadDatabaseTool()]
)


let response = try await session.respond(
    to: "Find three sourdough bread recipes"
)

```

--------------------------------

### Access Raw Response Content (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/rawcontent

This snippet demonstrates how to access the raw response content from a Foundation Model using the 'rawContent' property. This property is of type 'GeneratedContent' and reflects the unprocessed output of the model. It is available on multiple Apple platforms starting from OS version 26.0.

```swift
let rawContent: GeneratedContent
```

--------------------------------

### Declare Content Tagging Use Case

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase/contenttagging

This code snippet declares the static constant `contentTagging` for the `SystemLanguageModel.UseCase`. This use case is specifically designed for content tagging functionalities, enabling the model to categorize and organize data by generating relevant tags based on input prompts. It is available on multiple Apple platforms starting from version 26.0.

```swift
static let contentTagging: SystemLanguageModel.UseCase
```

--------------------------------

### Stream Response with Schema - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28schema%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

This Swift code snippet demonstrates how to use the `streamResponse` method to generate a streaming response from a language model, guiding the output with a specified schema. It accepts a schema, optional parameters for including the schema in the prompt and generation options, and a prompt closure.

```swift
final func streamResponse(
    schema: GenerationSchema,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```

--------------------------------

### Related Prompt Building Methods (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildexpression%28_%3A%29

This section outlines several related static methods for building prompts in Swift. These include creating builders from arrays, blocks, conditional components (either/or), limited availability prompts, and optional components. These methods are part of the FoundationModels framework.

```swift
static func buildArray([some PromptRepresentable]) -> Prompt
```

```swift
static func buildBlock<each P>(repeat each P) -> Prompt
```

```swift
static func buildEither(first: some PromptRepresentable) -> Prompt
```

```swift
static func buildEither(second: some PromptRepresentable) -> Prompt
```

```swift
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
```

```swift
static func buildOptional(Prompt?) -> Prompt
```

--------------------------------

### Define structured data for generation with @Generable macro

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

This Swift code defines data structures (`Itinerary`, `DayPlan`, `Activity`, `Kind`) using the `@Generable` macro to control model generation. The `@Guide` attribute is used to specify constraints and descriptions for properties, influencing the content generated by the model. This enables constrained sampling and the creation of structured content.

```swift
@Generable
struct Itinerary: Equatable {
    @Guide(description: "An exciting name for the trip.")
    let title: String
    @Guide(.anyOf(ModelData.landmarkNames))
    let destinationName: String
    let description: String
    @Guide(description: "An explanation of how the itinerary meets the person's special requests.")
    let rationale: String


    @Guide(description: "A list of day-by-day plans.")
    @Guide(.count(3))
    let days: [DayPlan]
}


@Generable
struct DayPlan: Equatable {
    @Guide(description: "A unique and exciting title for this day plan.")
    let title: String
    let subtitle: String
    let destination: String


    @Guide(.count(3))
    let activities: [Activity]
}


@Generable
struct Activity: Equatable {
    let type: Kind
    let title: String
    let description: String
}


@Generable
enum Kind {
    case sightseeing
    case foodAndDining
    case shopping
    case hotelAndLodging
}
```

--------------------------------

### Swift: Create Optional Instruction Builder

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional%28_%3A%29

The `buildOptional(_:)` static method in Swift creates an `Instructions` builder that incorporates an optional component. This is useful when a part of the instruction sequence might not be present. It takes an optional `Instructions` object as input and returns a configured `Instructions` object.

```swift
static func buildOptional(_ instructions: Instructions?) -> Instructions
```

--------------------------------

### Define Numeric Value - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/number%28_%3A%29

Represents a numeric value using the `number` case within the `GeneratedContent.Kind` enum. This case accepts a `Double` as its parameter to store the numeric value. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
case number(Double)
```

--------------------------------

### Initialize Generated Content with a Sequence

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28elements%3Aid%3A%29

This initializer creates generated content from a sequence of elements that conform to `ConvertibleToGeneratedContent`. It allows for an optional `GenerationID` to be specified. Requires iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, or visionOS 26.0+.

```swift
init<S>(
    elements: S,
    id: GenerationID? = nil
) where S : Sequence, S.Element == any ConvertibleToGeneratedContent
```

--------------------------------

### Declare promptRepresentation Instance Property in Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptrepresentable/promptrepresentation

This Swift code snippet shows the declaration of the `promptRepresentation` instance property. It's marked with the `@PromptBuilder` attribute and has a `get` accessor, indicating it provides a computed property that returns a `Prompt` object. This is a required property with a default implementation provided.

```swift
@PromptBuilder
var promptRepresentation: Prompt { get }
```

--------------------------------

### Access Instruction Content - Transcript.Instructions (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/instructions

Inspect the content of Transcript.Instructions to understand the model's behavior and available tools. The `segments` property holds the natural language instructions, while `toolDefinitions` lists the tools made available to the model.

```swift
var segments: [Transcript.Segment]
var toolDefinitions: [Transcript.ToolDefinition]
```

--------------------------------

### Define Game Character with Persona - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Defines a game character, 'Barista', using the 'Character' protocol. It includes properties like display name, persona description, and a fixed error response for generation issues. The persona is a detailed text that guides the AI model's behavior and role-playing.

```swift
struct Barista: Character {
    let id = UUID()
    let displayName = "Barista"
    let firstLine = "Hey there. Can you get the dream orders?"


    let persona = """
        Chike is the head barista at Dream Coffee, and loves serving up the perfect cup of coffee 
        to all the dreamers and creatures in the dream realm. Today is a particularly busy day, so 
        Chike is happy to have the help of a new trainee barista named Player.
        """


    let errorResponse = "Maybe let's stop chatting? We've got coffee to serve."
}

```

--------------------------------

### Related Tool Properties

Source: https://developer.apple.com/documentation/foundationmodels/tool/name

Information about other essential properties for Foundation Models tools, including description, schema inclusion, and parameters.

```APIDOC
## See Also

### Getting the tool properties

`var description: String`
A natural language description of when and how to use the tool.

**Required**

`var includesSchemaInInstructions: Bool`
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

**Required**. Default implementation provided.

`var parameters: GenerationSchema`
A schema for the parameters this tool accepts.

**Required**. Default implementation provided.
```

--------------------------------

### Accessing Content of a Structured Segment (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment/content

This snippet demonstrates how to access the 'content' property of a structured segment. The 'content' property returns a 'GeneratedContent' object, which represents the actual data of the segment. This functionality is available on iOS, iPadOS, macOS, visionOS, and Mac Catalyst starting from version 26.0.

```swift
var content: GeneratedContent { get set }
```

--------------------------------

### Remove Obsolete Adapters (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/removeobsoleteadapters%28%29

The `removeObsoleteAdapters()` static method is part of the FoundationModels framework. It removes all adapters that are no longer compatible with the current system language models. This operation can throw errors, so it should be handled within a `try-catch` block. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
static func removeObsoleteAdapters() throws
```

--------------------------------

### Create Limited Availability Instructions Builder (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildlimitedavailability%28_%3A%29

This Swift method creates an `Instructions` builder for prompts with limited availability. It requires an argument that conforms to `InstructionsRepresentable`. This is useful for scenarios where certain instructions should only be presented under specific conditions.

```swift
static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### DynamicGenerationSchema.Property Initialization

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/property

Details on how to create a Property for a dynamic generation schema, including its name, description, schema, and optional status.

```APIDOC
## Creating a property

### Description
Creates a property referencing a dynamic schema.

### Method
`init(name: String, description: String?, schema: DynamicGenerationSchema, isOptional: Bool)`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```json
{
  "example": "Property creation example"
}
```

### Response
#### Success Response (200)
None

#### Response Example
```json
{
  "example": "Property response example"
}
```
```

--------------------------------

### Stream Response with Schema - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28to%3Aschema%3Aincludeschemainprompt%3Aoptions%3A%29

This Swift code snippet demonstrates how to use the `streamResponse` method to get a streaming response from a language model based on a provided prompt and schema. It utilizes `Prompt`, `GenerationSchema`, and `GenerationOptions` to configure the request and `LanguageModelSession.ResponseStream<GeneratedContent>` to process the output. Ensure JavaScript is enabled for full page functionality.

```swift
final func streamResponse(
    to prompt: Prompt,
    schema: GenerationSchema,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
) -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```

--------------------------------

### Create Generation Schema with Root and Dependencies

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/init%28root%3Adependencies%3A%29

Initializes a generation schema by providing a root schema and an array of dynamic schemas as dependencies. This initializer is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS versions 26.0 and later.

```swift
init(
    root: DynamicGenerationSchema,
    dependencies: [DynamicGenerationSchema]
) throws
```

--------------------------------

### Create Prompt Builder from Expression (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28first%3A%29

This method is used to create a prompt builder directly from a Swift expression. It allows for seamless integration of various Swift constructs into the prompt building process.

```swift
static func buildExpression(_: some PromptRepresentable) -> Prompt
```

--------------------------------

### Define GenerationError Enum

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror

Defines the GenerationError enumeration, which represents various errors that can occur during language model response generation. It includes cases for unavailable assets, decoding failures, context window limits, guardrail violations, rate limiting, refusals, concurrent requests, and unsupported guides or languages.

```swift
enum GenerationError
```

--------------------------------

### Foundation Models - buildOptional

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock%28_%3A%29

Creates a builder with an optional component, allowing for non-mandatory parts of instructions.

```APIDOC
## buildOptional

### Description
Creates a builder with an optional component. This method is used when a part of the instruction sequence is optional and may or may not be present.

### Method
`static func buildOptional(Instructions?) -> Instructions`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **instruction** (Instructions?) - Optional - The optional instruction component.

### Request Example (with optional instruction)
```json
{
  "instruction": {
    "type": "OptionalStep",
    "details": "..."
  }
}
```

### Request Example (without optional instruction)
```json
{
  "instruction": null
}
```

### Response
#### Success Response (200)
- **Instructions** (Instructions) - The constructed `Instructions` object.

#### Response Example (with optional instruction)
```json
{
  "instructions": {
    "type": "Instructions",
    "component": {
      "type": "OptionalStep",
      "details": "..."
    }
  }
}
```

#### Response Example (without optional instruction)
```json
{
  "instructions": {
    "type": "Instructions",
    "component": null
  }
}
```
```

--------------------------------

### Use GenerationID with SwiftUI and LanguageModelSession in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generationid

Demonstrates how to use GenerationID to uniquely identify generated content within a SwiftUI List. It shows how LanguageModelSession streams responses, and how GenerationID ensures stable identification of `Person` objects even as their names change. This example highlights the stability guarantee of GenerationID for identified elements.

```swift
@Generable
struct Person: Equatable {
    var name: String
}


struct PeopleView: View {
    @State private var session = LanguageModelSession()
    @State private var people = [Person.PartiallyGenerated]()
    
    var body: some View {
        // A person's name changes as the response is generated,
        // and two people can have the same name, so it's not suitable
        // for use as an id.
        //
        // `GenerationID` receives special treatment and is guaranteed
        // to be both present and stable.
        List {
            // The framework generates each instance with a `GenerationID`.
            ForEach(people, id: \.id) { person in
                Text("Name: \(person.name ?? "")")
            }
        }
        .task {
            do {
                for try await people in session.streamResponse(
                    to: "Who were the first 3 presidents of the US?",
                    generating: [Person].self
                ) {
                    withAnimation {
                        self.people = people.content
                    }
                }
            } catch {
                // Handle the thrown error.
            }
        }
    }
}
```

--------------------------------

### Get Issue Category - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

This code snippet demonstrates how to retrieve different issue categories for language model feedback in Swift. It includes cases for `didNotFollowInstructions`, `incorrect`, `suggestiveOrSexual`, `tooVerbose`, `triggeredGuardrailUnexpectedly`, `unhelpful`, and `vulgarOrOffensive`. These cases help categorize specific issues encountered with language model responses.

```swift
case didNotFollowInstructions
case incorrect
case suggestiveOrSexual
case tooVerbose
case triggeredGuardrailUnexpectedly
case unhelpful
case vulgarOrOffensive
```

--------------------------------

### SystemLanguageModel.Adapter.AssetError.Context Initializer

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror/context/init%28debugdescription%3A%29

Initializes the SystemLanguageModel.Adapter.AssetError.Context with a given debug description.

```APIDOC
## SystemLanguageModel.Adapter.AssetError.Context Initializer

### Description
Initializes the SystemLanguageModel.Adapter.AssetError.Context with a given debug description.

### Method
Initializer

### Endpoint
N/A

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
init(debugDescription: String)
```

### Response
#### Success Response (200)
N/A

#### Response Example
N/A
```

--------------------------------

### Accessing Generation ID in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/id

This snippet demonstrates how to access the unique and stable 'id' property of a GeneratedContent object. The 'id' is present for responses generated by a LanguageModelSession but is nil for manually initialized instances. This property is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
var id: GenerationID?

```

--------------------------------

### Declare Exceeded Context Window Size Error

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/exceededcontextwindowsize%28_%3A%29

This code snippet declares the `exceededContextWindowSize` error case within the `LanguageModelSession.GenerationError` enum. This error signals that the session has reached its context window size limit, preventing further generation. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS starting from version 26.0.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```

--------------------------------

### Initialize Content Tagging Session in Swift

Source: https://developer.apple.com/documentation/foundationmodels/documentation/FoundationModels/categorizing-and-organizing-data-with-content-tags

Initializes a session for content tagging using the `SystemLanguageModel` with the `.contentTagging` use case. This prepares the model for generating relevant tags for provided text.

```swift
// Create an instance of the model with the content tagging use case.
let model = SystemLanguageModel(useCase: .contentTagging)



// Initialize a session with the model.
let session = LanguageModelSession(model: model)
```

--------------------------------

### Define Generable Type for Content Tagging Results - Swift

Source: https://developer.apple.com/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags

This code defines a custom Swift struct `ContentTaggingResult` that conforms to the `Generable` protocol. It uses `@Guide` attributes to specify the types and maximum counts of tags (actions, emotions, objects, topics) the model should generate, enabling structured output.

```swift
@Generable
struct ContentTaggingResult {
    @Guide(
        description: "Most important actions in the input text.",
        .maximumCount(2)
    )
    let actions: [String]


    @Guide(
        description: "Most important emotions in the input text.",
        .maximumCount(3)
    )
    let emotions: [String]


    @Guide(
        description: "Most important objects in the input text.",
        .maximumCount(5)
    )
    let objects: [String]


    @Guide(
        description: "Most important topics in the input text.",
        .maximumCount(2)
    )
    let topics: [String]

}
```

--------------------------------

### Foundation Models - Other Builder Methods

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

Documentation for other builder methods available in Foundation Models.

```APIDOC
## Foundation Models Builder Methods

### Description
Provides methods for building instructions in various ways.

### Methods

#### `static func buildBlock<each I>(repeat each I) -> Instructions`
Creates a builder with a block of instructions.

#### `static func buildEither(first: some InstructionsRepresentable) -> Instructions`
Creates a builder with the first component of an either/or choice.

#### `static func buildEither(second: some InstructionsRepresentable) -> Instructions`
Creates a builder with the second component of an either/or choice.

#### `static func buildExpression(_:) -> Instructions`
Creates a builder with a prompt expression.

#### `static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions`
Creates a builder with a limited availability prompt.

#### `static func buildOptional(Instructions?) -> Instructions`
Creates a builder with an optional component.

### Request Example
```swift
// Example for buildBlock:
let blockInstructions = FoundationModel.buildBlock(Prompt1(), Prompt2())

// Example for buildEither (first):
let eitherFirst = FoundationModel.buildEither(first: Prompt1())

// Example for buildOptional:
let optionalPrompt: Instructions? = nil
let optionalInstructions = FoundationModel.buildOptional(optionalPrompt)
```

### Response
All these methods return an `Instructions` object upon success.
```

--------------------------------

### Foundation Models - Prompt Construction

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildexpression%28_%3A%29

This section details the methods available for constructing and manipulating prompts using the Foundation Models API.

```APIDOC
## Foundation Models - Prompt Construction Utilities

### Description
Provides methods for building and composing prompts for use with Foundation Models.

### Methods

#### `buildExpression(_:)`
Creates a builder with a prompt expression.

- **iOS:** 26.0+
- **iPadOS:** 26.0+
- **Mac Catalyst:** 26.0+
- **macOS:** 26.0+
- **visionOS:** 26.0+

##### Declaration
```swift
static func buildExpression(_ expression: Prompt) -> Prompt
```

#### `buildArray(_:)`
Creates a builder with an array of prompts.

##### Parameters
- **prompts**: `[some PromptRepresentable]` - An array of prompt-representable elements.

##### Returns
`Prompt` - A new prompt builder.

#### `buildBlock<each P>(repeat each P)`
Creates a builder with a block of prompts.

##### Parameters
- **P**: `repeat each P` - A variadic list of prompt-representable elements.

##### Returns
`Prompt` - A new prompt builder.

#### `buildEither(first:)`
Creates a builder with the first component of an either-or choice.

##### Parameters
- **first**: `some PromptRepresentable` - The first prompt-representable element.

##### Returns
`Prompt` - A new prompt builder.

#### `buildEither(second:)`
Creates a builder with the second component of an either-or choice.

##### Parameters
- **second**: `some PromptRepresentable` - The second prompt-representable element.

##### Returns
`Prompt` - A new prompt builder.

#### `buildLimitedAvailability(_:)`
Creates a builder with a limited availability prompt.

##### Parameters
- **prompt**: `some PromptRepresentable` - The prompt-representable element.

##### Returns
`Prompt` - A new prompt builder.

#### `buildOptional(_:)`
Creates a builder with an optional component.

##### Parameters
- **prompt**: `Prompt?` - An optional prompt.

##### Returns
`Prompt` - A new prompt builder.
```

--------------------------------

### SystemLanguageModel.Adapter - Checking compatibility

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter

Checks the compatibility of adapters with current system models and devices.

```APIDOC
### Checking compatibility

#### Static Methods

- **`static func compatibleAdapterIdentifiers(name: String) -> [String]`**

Get all compatible adapter identifiers compatible with current system models.

- **`static func isCompatible(AssetPack) -> Bool`**

Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.
```

--------------------------------

### Swift Struct for Instructions

Source: https://developer.apple.com/documentation/foundationmodels/instructions

Defines the 'Instructions' structure, a fundamental component for configuring foundation models. This serves as a type definition for how instructions are represented within the framework.

```swift
struct Instructions
```

--------------------------------

### Accessing the Tool that Caused a ToolCallError

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror/tool

This code snippet demonstrates how to access the 'tool' property from a LanguageModelSession.ToolCallError. The 'tool' property provides a reference to the specific tool that was invoked and resulted in the error. This is useful for debugging and understanding the failure context within a language model session. Availability starts from iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, and visionOS 26.0.

```swift
var tool: any Tool
```

--------------------------------

### Initialize Foundation Model Adapter from File URL

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/init%28fileurl%3A%29

Creates an adapter for Foundation Models using a file URL. This initializer may throw an `AssetLoadingError` if the provided `fileURL` is invalid. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS from version 26.0 onwards.

```swift
init(fileURL: URL) throws
```

--------------------------------

### Availability Cases for SystemLanguageModel

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason

This snippet shows the possible states of SystemLanguageModel.Availability. It includes a case for when the system is ready (`available`) and a case for when it is not ready, providing the specific reason for unavailability.

```swift
case available
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```

--------------------------------

### Swift: buildOptional(_:) Method for Prompt Construction

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildoptional%28_%3A%29

The `buildOptional(_:)` method creates a prompt builder that includes an optional component. This is useful for conditionally adding parts to a prompt. It takes an optional `Prompt` as input and returns a `Prompt`.

```swift
static func buildOptional(_ component: Prompt?) -> Prompt
```

--------------------------------

### GeneratedContent Initializer

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28json%3A%29

Initializes GeneratedContent from a JSON string. This initializer is useful for handling partially generated responses and creating content even when the JSON string might be incomplete.

```APIDOC
## init(json:)

### Description
Creates equivalent content from a JSON string. This initializer is useful for correctly handling partially generated responses where the JSON string may be incomplete.

### Method
`init(json: String) throws`

### Endpoint
N/A (Initializers are not REST endpoints)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let partialJson = #"{"title": "A story of"}"#
try {
    let generatedContent = try GeneratedContent(json: partialJson)
    // Use generatedContent here
} catch {
    print("Error initializing GeneratedContent: \(error)")
}
```

### Response
#### Success Response (Initializer)
Initializes an instance of `GeneratedContent`.

#### Response Example
N/A (Initializers do not return a response in the typical API sense, they create an object instance.)

## Discussion
The JSON string provided to this initializer may be incomplete. This is particularly useful for correctly handling partially generated responses from models.
```

--------------------------------

### Building Instructions with Arrays

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder

Provides static methods for the `InstructionsBuilder` to construct `Instructions` from an array of `InstructionsRepresentable` types or a variadic list of types.

```swift
static func buildArray<InstructionsRepresentable>(_ prompts: [InstructionsRepresentable]) -> Instructions
static func buildBlock<each I>(repeat each I) -> Instructions
```

--------------------------------

### Build Either Prompt (First Component) - Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28second%3A%29

Creates a prompt builder that includes the first component of a choice. This function is the counterpart to `buildEither(second:)` and is used when selecting the initial option in a conditional prompt structure. It is available on Apple platforms.

```swift
static func buildEither(first: some PromptRepresentable) -> Prompt
```

--------------------------------

### LanguageModelFeedback.Issue Initialization

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue

Describes how to initialize an `Issue` object, specifying the category of the issue and an optional explanation.

```APIDOC
## POST /websites/developer_apple_foundationmodels/LanguageModelFeedback/Issue

### Description
Initializes a new `Issue` object, which represents a category of problem with the model's response, along with an optional textual explanation.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/LanguageModelFeedback/Issue`

### Parameters
#### Request Body
- **category** (LanguageModelFeedback.Issue.Category) - Required - The category of the issue.
- **explanation** (String) - Optional - A detailed explanation of the issue.
```

--------------------------------

### Compile Draft Model for Faster Inference

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Compiles the draft model of a Foundation Model adapter to potentially speed up inference. This is an optional step that can be performed after ensuring the adapter is downloaded. Compilation is computationally expensive and should be handled with care, potentially using background tasks.

```swift
// Load the adapter.
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


// Wait for download to complete.
if await checkAdapterDownload(name: "myAdapter") {
    do {
        // You can use your adapter without compiling the draft model, or during
        // compilation, but running inference with your adapter might be slower.
        try await adapter.compile()
    } catch let error {
        // Handle the draft model compilation error.
    }
}

```

--------------------------------

### Create Reference Schema with init(referenceTo:)

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init%28referenceto%3A%29

Initializes a reference schema by providing the name of the DynamicGenerationSchema it refers to. This initializer is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS version 26.0 and later.

```swift
init(referenceTo name: String)
```

--------------------------------

### Foundation Models - buildArray

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock%28_%3A%29

Creates a builder with an array of prompts, useful for creating instructions from a collection.

```APIDOC
## buildArray

### Description
Creates a builder with an array of prompts. This method is used to construct instructions from an array of components that conform to `InstructionsRepresentable`.

### Method
`static func buildArray(_: [some InstructionsRepresentable]) -> Instructions`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **prompts** (Array<some InstructionsRepresentable>) - Required - An array of prompts conforming to `InstructionsRepresentable`.

### Request Example
```json
{
  "prompts": [
    {
      "type": "Prompt1",
      "text": "..."
    },
    {
      "type": "Prompt2",
      "text": "..."
    }
  ]
}
```

### Response
#### Success Response (200)
- **Instructions** (Instructions) - The constructed `Instructions` object.

#### Response Example
```json
{
  "instructions": {
    "type": "Instructions",
    "components": [
      {
        "type": "Prompt1",
        "text": "..."
      },
      {
        "type": "Prompt2",
        "text": "..."
      }
    ]
  }
}
```
```

--------------------------------

### Foundation Models - Response Format Initialization

Source: https://developer.apple.com/documentation/foundationmodels/transcript/responseformat/init%28type%3A%29

This section details how to create a response format for Foundation Models using a specified type.

```APIDOC
## init(type:)

### Description
Creates a response format with the type you specify.

### Method
Initializer

### Endpoint
N/A (Initializer)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
N/A

### Response
#### Success Response (200)
N/A

#### Response Example
N/A

### See Also
- `init(schema: GenerationSchema)`: Creates a response format with a schema.
```

--------------------------------

### Tool Protocol Overview

Source: https://developer.apple.com/documentation/foundationmodels/tool

Defines the structure and behavior of tools that language models can invoke to gather information or perform actions.

```APIDOC
## Protocol Tool<Arguments, Output>

### Description
A tool that a model can call to gather information at runtime or perform side effects. It allows models to interact with your code to incorporate real-time data or execute specific tasks.

### Method
N/A (Protocol Definition)

### Endpoint
N/A (Protocol Definition)

### Parameters
#### Associated Types
- **Arguments** (`ConvertibleFromGeneratedContent`) - The arguments that this tool accepts.
- **Output** (`PromptRepresentable`) - The output that this tool produces for the language model.

#### Properties
- **name** (`String`) - A unique name for the tool.
- **description** (`String`) - A natural language description of when and how to use the tool.
- **includesSchemaInInstructions** (`Bool`) - If true, the model’s name, description, and parameters schema will be injected into the instructions.
- **parameters** (`GenerationSchema`) - A schema for the parameters this tool accepts.

### Request Example
```json
{
  "tool_name": "FindContacts",
  "arguments": {
    "count": 5
  }
}
```

### Response
#### Success Response (Tool Output)
- **Output** (`PromptRepresentable`) - The result returned by the tool after execution.

#### Response Example
```json
[
  "John Doe",
  "Jane Smith",
  "Peter Jones"
]
```

### Error Handling
- **LanguageModelSession.GenerationError.exceededContextWindowSize(_:)** - Thrown if the session exceeds the available context size.
```

--------------------------------

### Initialize Content Tagging Model and Session (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags

This code snippet demonstrates how to create an instance of the `SystemLanguageModel` for the content tagging use case and then initialize a `LanguageModelSession` with that model. This session is used to interact with the model for generating tagged responses.

```swift
import Foundation

// Create an instance of the model with the content tagging use case.
let model = SystemLanguageModel(useCase: .contentTagging)




// Initialize a session with the model.
let session = LanguageModelSession(model: model)
```

--------------------------------

### Create Prompt Builder with Block (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28first%3A%29

This method creates a prompt builder from a block of code. It utilizes Swift's variadic generics (`repeat each P`) to accept any number of `PromptRepresentable` types and combine them into a single `Prompt`.

```swift
static func buildBlock<each P>(repeat each P) -> Prompt
```

--------------------------------

### Transcript.StructuredSegment Initializer

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment/init%28id%3Asource%3Acontent%3A%29

Initializes a new instance of a structured segment for transcript content.

```APIDOC
## Initializer: init(id:source:content:)

### Description
Initializes a new instance of a structured segment with a unique identifier, source information, and the generated content.

### Method
Initializer

### Endpoint
N/A (This is an initializer for a class)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let structuredSegment = Transcript.StructuredSegment(
    id: "some-unique-id",
    source: "user-input",
    content: GeneratedContent(...)
)
```

### Response
#### Success Response (200)
N/A (Initializers do not return responses in the traditional API sense)

#### Response Example
N/A
```

--------------------------------

### LanguageModelSession - Respond to Prompt

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Aoptions%3A%29

The `respond(to:options:)` method allows you to send a prompt to the language model and receive a text-based response. You can control the generation process using `GenerationOptions`.

```APIDOC
## POST /foundationmodels/languageModelSession/respond

### Description
Produces a response to a prompt with optional generation controls.

### Method
POST

### Endpoint
/foundationmodels/languageModelSession/respond

### Parameters
#### Request Body
- **prompt** (Prompt) - Required - The input prompt for the model.
- **options** (GenerationOptions) - Optional - Controls token sampling and generation behavior. Defaults to `GenerationOptions()`.

### Request Example
```json
{
  "prompt": {
    "text": "What is the capital of France?"
  },
  "options": {
    "temperature": 0.7,
    "maxTokens": 100
  }
}
```

### Response
#### Success Response (200)
- **text** (String) - The generated text response from the model.

#### Response Example
```json
{
  "text": "The capital of France is Paris."
}
```
```

--------------------------------

### LanguageModelSession - Respond

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Aoptions%3A%29-b2re

This API endpoint allows you to generate a response from a foundation model by providing a prompt and optional generation configurations.

```APIDOC
## POST /foundationmodels/languagesession/respond

### Description
Produces a response to a prompt using the LanguageModelSession.

### Method
POST

### Endpoint
/foundationmodels/languagesession/respond

### Parameters
#### Request Body
- **prompt** (String) - Required - A prompt for the model to respond to.
- **options** (GenerationOptions) - Optional - GenerationOptions that control how tokens are sampled from the distribution the model produces.

### Request Example
```json
{
  "prompt": "What is the capital of France?",
  "options": {
    "temperature": 0.7,
    "maxTokens": 100
  }
}
```

### Response
#### Success Response (200)
- **result** (String) - A string composed of the tokens produced by sampling model output.

#### Response Example
```json
{
  "result": "The capital of France is Paris."
}
```
```

--------------------------------

### Initialize Foundation Model with Custom Adapter

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Initializes the base version of a system language model with a specific adapter and guardrails. This convenience initializer is used when you need to customize the model's behavior for particular use cases.

```swift
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
```

--------------------------------

### FoundationModels - init(_:id:)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28_%3Aid%3A%29

Initializes Foundation Models content with a single value and a custom GenerationID.

```APIDOC
## init(_:id:)

### Description
Creates content that contains a single value with a custom `GenerationID`.

### Method
Initializer

### Endpoint
N/A (Initializer)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
```swift
init(
    _ value: some ConvertibleToGeneratedContent,
    id: GenerationID
)
```

### Response
#### Success Response (200)
N/A (Initializer)

#### Response Example
N/A (Initializer)
```

--------------------------------

### SystemLanguageModel Initializer

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/init%28usecase%3Aguardrails%3A%29

Initializes a SystemLanguageModel with specified use case and guardrails.

```APIDOC
## init(useCase:guardrails:)

### Description
Creates a system language model for a specific use case.

### Method
`convenience init`

### Parameters
#### Query Parameters
- **useCase** (SystemLanguageModel.UseCase) - Optional - Defaults to .general. Represents the use case for prompting.
- **guardrails** (SystemLanguageModel.Guardrails) - Optional - Defaults to Guardrails.default. Flags sensitive content from model input and output.

### Request Example
```swift
convenience init(
    useCase: SystemLanguageModel.UseCase = .general,
    guardrails: SystemLanguageModel.Guardrails = Guardrails.default
)
```

### Response
#### Success Response (200)
N/A (Initializers do not return a response in the traditional sense)

### See Also
- `struct UseCase`: A type that represents the use case for prompting.
- `struct Guardrails`: Guardrails flag sensitive content from model input and output.
```

--------------------------------

### Create and Use LanguageModelSession

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

Demonstrates how to create a LanguageModelSession with specific instructions and then use it to generate a response to a prompt. This involves defining the model's role and providing a query.

```swift
let instructions = """\nYou are a motivational workout coach that provides quotes to inspire \nand motivate athletes.\n"""
let session = LanguageModelSession(instructions: instructions)
let prompt = "Generate a motivational quote for my next workout."
let response = try await session.respond(to: prompt)
```

--------------------------------

### Create ToolCalls Instance

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcalls

Initializes a `ToolCalls` instance with a unique identifier and a collection of tool call identifiers. This method is used to programmatically create a collection of tool calls.

```swift
init<S>(id: String, S)
```

--------------------------------

### Foundation Models - buildLimitedAvailability

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock%28_%3A%29

Creates a builder with a limited availability prompt, for prompts with specific conditions.

```APIDOC
## buildLimitedAvailability

### Description
Creates a builder with a limited availability prompt. This method is used for prompts that are only available under certain conditions or for specific platforms.

### Method
`static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **prompt** (some InstructionsRepresentable) - Required - The prompt with limited availability.

### Request Example
```json
{
  "prompt": {
    "type": "ConditionalPrompt",
    "condition": "iOS 17.0+",
    "content": "..."
  }
}
```

### Response
#### Success Response (200)
- **Instructions** (Instructions) - The constructed `Instructions` object.

#### Response Example
```json
{
  "instructions": {
    "type": "Instructions",
    "component": {
      "type": "ConditionalPrompt",
      "condition": "iOS 17.0+",
      "content": "..."
    }
  }
}
```
```

--------------------------------

### Prompt Generation Options - Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/segments

This code snippet shows how to access the generation options associated with a prompt. The 'options' property provides configuration details for how the model should generate a response.

```swift
var options: GenerationOptions
```

--------------------------------

### Create Prompt Builder with Optional Component (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28first%3A%29

This method constructs a prompt builder from an optional prompt. It takes an optional `PromptRepresentable` and returns a `Prompt`, enabling the inclusion of optional parts in a prompt sequence.

```swift
static func buildOptional(_: Prompt?) -> Prompt
```

--------------------------------

### GenerationOptions Initialization

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions

Creates generation options that control token sampling behavior.

```APIDOC
## `init(sampling: GenerationOptions.SamplingMode?, temperature: Double?, maximumResponseTokens: Int?)`

### Description
Creates generation options that control token sampling behavior.

### Method
`init`

### Parameters
#### Path Parameters
* None

#### Query Parameters
* None

#### Request Body
* `sampling` (GenerationOptions.SamplingMode?) - Optional - A sampling strategy for how the model picks tokens when generating a response.
* `temperature` (Double?) - Optional - Temperature influences the confidence of the model's response.
* `maximumResponseTokens` (Int?) - Optional - The maximum number of tokens the model is allowed to produce in its response.

### Request Example
```json
{
  "sampling": {"value": "top_k", "parameter": 50},
  "temperature": 0.7,
  "maximumResponseTokens": 100
}
```

### Response
#### Success Response (200)
* None (This is an initializer, not an endpoint returning data)

#### Response Example
* None
```

--------------------------------

### Generate Content with Schema and Prompt (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28schema%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

This Swift method generates content using a specified schema and prompt. It allows customization of schema inclusion in the prompt and generation options. The method returns a `LanguageModelSession.Response` containing `GeneratedContent`.

```swift
@discardableResult nonisolated(nonsending)
final func respond(
    schema: GenerationSchema,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
) async throws -> LanguageModelSession.Response<GeneratedContent>
```

--------------------------------

### Foundation Models - buildEither

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock%28_%3A%29

Creates a builder with either the first or second component, used for conditional instruction paths.

```APIDOC
## buildEither

### Description
Creates a builder with either the first or second component. This method is useful for implementing conditional logic in instruction sequences.

### Method
`static func buildEither(first: some InstructionsRepresentable) -> Instructions`
`static func buildEither(second: some InstructionsRepresentable) -> Instructions`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **first** (some InstructionsRepresentable) - Required - The first component to include.
- **second** (some InstructionsRepresentable) - Required - The second component to include.

### Request Example (first)
```json
{
  "first": {
    "type": "ConditionalPath1",
    "data": "..."
  }
}
```

### Request Example (second)
```json
{
  "second": {
    "type": "ConditionalPath2",
    "data": "..."
  }
}
```

### Response
#### Success Response (200)
- **Instructions** (Instructions) - The constructed `Instructions` object.

#### Response Example
```json
{
  "instructions": {
    "type": "Instructions",
    "component": {
      "type": "ConditionalPath1",
      "data": "..."
    }
  }
}
```
```

--------------------------------

### Create Object Schema - Swift

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init%28name%3Adescription%3Aproperties%3A%29

Initializes a new object schema for dynamic generation. It requires a unique name, an optional descriptive string, and an array of properties that define the schema's structure. This is fundamental for defining complex data structures.

```swift
init(
    name: String,
    description: String? = nil,
    properties: [DynamicGenerationSchema.Property]
)
```

--------------------------------

### Configure LanguageModelSession with Custom Tools and Instructions

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

Initializes a LanguageModelSession for itinerary planning. It takes a Landmark object and configures the session with a custom tool (FindPointsOfInterestTool) and detailed instructions for generating daily itineraries including activities, hotels, and restaurants. The landmark's description is used as context.

```swift
init(landmark: Landmark) {
    self.landmark = landmark
    Logging.general.log("The landmark is... \(landmark.name)")
    let pointOfInterestTool = FindPointsOfInterestTool(landmark: landmark)
    self.session = LanguageModelSession(
        tools: [pointOfInterestTool],
        instructions: Instructions {
            "Your job is to create an itinerary for the person."
            
            "Each day needs an activity, hotel and restaurant."
            
            """
            Always use the findPointsOfInterest tool to find businesses \ 
            and activities in \(landmark.name), especially hotels \ 
            and restaurants.
            
            The point of interest categories may include:
            """
            FindPointsOfInterestTool.categories
            
            """
            Here is a description of \(landmark.name) for your reference \ 
            when considering what activities to generate:
            """
            landmark.description
        }
    )
    self.pointOfInterestTool = pointOfInterestTool
}
```

--------------------------------

### Transcript.Prompt Structure

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt

Details on the Transcript.Prompt structure, including its initialization and properties.

```APIDOC
## Transcript.Prompt

### Description
A prompt from the user to the model.

### Method
N/A (Structure Definition)

### Endpoint
N/A (Structure Definition)

### Parameters
#### Initializer: `init(id: String, segments: [Transcript.Segment], options: GenerationOptions, responseFormat: Transcript.ResponseFormat?`
- **id** (String) - Required - The identifier of the prompt.
- **segments** ([Transcript.Segment]) - Required - Ordered prompt segments.
- **options** (GenerationOptions) - Required - Generation options associated with the prompt.
- **responseFormat** (Transcript.ResponseFormat?) - Optional - An optional response format that describes the desired output structure.

### Properties
- **id** (String) - The identifier of the prompt.
- **responseFormat** (Transcript.ResponseFormat?) - An optional response format that describes the desired output structure.
- **segments** ([Transcript.Segment]) - Ordered prompt segments.
- **options** (GenerationOptions) - Generation options associated with the prompt.

### Request Example
```json
{
  "id": "user_prompt_123",
  "segments": [
    {
      "text": "What is the weather today?"
    }
  ],
  "options": {
    "temperature": 0.7
  },
  "responseFormat": {
    "type": "json",
    "schema": "{\"properties\": {\"weather\": {\"type\": \"string\"}}}"
  }
}
```

### Response Example
```json
{
  "id": "user_prompt_123",
  "segments": [
    {
      "text": "What is the weather today?"
    }
  ],
  "options": {
    "temperature": 0.7
  },
  "responseFormat": {
    "type": "json",
    "schema": "{\"properties\": {\"weather\": {\"type\": \"string\"}}}"
  }
}
```
```

--------------------------------

### GenerationID Initializer

Source: https://developer.apple.com/documentation/foundationmodels/generationid/init%28%29

This section describes the `init()` method used to create a new, unique `GenerationID`.

```APIDOC
## init()

### Description
Creates a new, unique `GenerationID`.

### Method
`init()`

### Endpoint
N/A (This is a constructor/initializer)

### Parameters
None

### Request Example
```swift
let generationID = GenerationID()
```

### Response
#### Success Response (N/A - This is an initializer)
- **GenerationID** (Object) - A newly created, unique identifier.

#### Response Example
(Conceptual - as this is an initializer)
```swift
// Represents a unique GenerationID object
```
```

--------------------------------

### Create Builder with Prompt Expression (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildexpression%28_%3A%29

The `buildExpression(_:)` method creates a builder containing a prompt expression. It takes a single argument, `expression` of type `Instructions`, and returns an `Instructions` object representing the built expression. This is part of a larger pattern for constructing instructions programmatically.

```swift
static func buildExpression(_ expression: Instructions) -> Instructions
```

--------------------------------

### LanguageModelSession - respond Method

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Agenerating%3Aincludeschemainprompt%3Aoptions%3A%29-13kji

The `respond` method is used to generate an object as a response to a given prompt. It allows customization of the response type, schema inclusion, and generation options.

```APIDOC
## POST /languageModelSession/respond

### Description
Produces a generable object as a response to a prompt. This method allows for flexible generation of content based on a provided text prompt and specified response type.

### Method
POST

### Endpoint
/languageModelSession/respond

### Parameters
#### Query Parameters
- **prompt** (String) - Required - A prompt for the model to respond to.
- **generating** (Content.Type) - Optional - A type to produce as the response. Defaults to `Content.self`.
- **includeSchemaInPrompt** (Bool) - Optional - Inject the schema into the prompt to bias the model. Defaults to `true`.
- **options** (GenerationOptions) - Optional - Options that control how tokens are sampled from the distribution the model produces. Defaults to `GenerationOptions()`.

### Request Body
This endpoint does not explicitly define a request body in the provided documentation. Parameters are expected to be passed as query parameters or within the method signature for programmatic use.

### Request Example
```json
{
  "prompt": "What is the capital of France?",
  "generating": "String",
  "includeSchemaInPrompt": true,
  "options": {}
}
```

### Response
#### Success Response (200)
- **response** (LanguageModelSession.Response<Content>) - An instance of the `Generable` type, representing the model's response.

#### Response Example
```json
{
  "response": {
    "generated": "Paris"
  }
}
```

### Discussion
It is recommended to use the default value of `true` for `includeSchemaInPrompt` unless the model has inherent knowledge of the expected response format. This parameter helps guide the model towards generating structured or specific types of content.

### Mentioned in
Generating Swift data structures with guided generation
```

--------------------------------

### Create Generated Content with Properties and ID

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28properties%3Aid%3A%29

Initializes generated content with a dictionary of properties and an optional unique identifier. The order of properties is critical for `Generable` types, aligning with their schema.

```swift
init(
    properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>,
    id: GenerationID? = nil
)
```

--------------------------------

### Prewarm Session Resources with Optional Prompt Prefix (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/prewarm%28promptprefix%3A%29

The prewarm(promptPrefix:) method loads session resources into memory and can optionally cache a prompt prefix to decrease request latency. It's recommended to use this when interaction is expected within seconds. Ensure at least one second passes before calling a respond method after prewarming.

```swift
final func prewarm(promptPrefix: Prompt? = nil)

```

--------------------------------

### Create a Language Model Session in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models

This code demonstrates how to create a `LanguageModelSession` object to interact with the Foundation Models. A new session should be created for each single-turn interaction. For multi-turn conversations where the model needs to retain context, the same session object should be reused.

```swift
// Create a session with the system model for a single-turn interaction.
let session = LanguageModelSession()

// To reuse the session for multi-turn interactions:
// let session = LanguageModelSession()
// // ... use session for multiple calls ...

```

--------------------------------

### Create Builder with Optional Component using buildOptional(_:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

The buildOptional(_:) static method creates a builder from an optional instruction component. This allows for conditionally including instructions in the building process. It accepts an optional Instructions object.

```swift
static func buildOptional(_ instruction: Instructions?) -> Instructions
```

--------------------------------

### Create Prompt Initializer in Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/init%28id%3Asegments%3Aoptions%3Aresponseformat%3A%29

This Swift code defines the initializer for creating a prompt. It accepts an optional ID, an array of transcript segments, optional generation options, and an optional response format. The ID defaults to a new UUID string, and options default to standard generation options.

```swift
init(
    id: String = UUID().uuidString,
    segments: [Transcript.Segment],
    options: GenerationOptions = GenerationOptions(),
    responseFormat: Transcript.ResponseFormat? = nil
)
```

--------------------------------

### Foundation Models - buildExpression

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock%28_%3A%29

Creates a builder with a prompt expression, used for embedding simple prompts.

```APIDOC
## buildExpression

### Description
Creates a builder with a prompt expression. This method is used to directly include a prompt as part of the instructions.

### Method
`static func buildExpression(_:)`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **prompt** (any) - Required - The prompt expression to include.

### Request Example
```json
{
  "prompt": {
    "type": "SimplePrompt",
    "text": "Please provide your input."
  }
}
```

### Response
#### Success Response (200)
- **Instructions** (Instructions) - The constructed `Instructions` object.

#### Response Example
```json
{
  "instructions": {
    "type": "Instructions",
    "component": {
      "type": "SimplePrompt",
      "text": "Please provide your input."
    }
  }
}
```
```

--------------------------------

### Foundation Models - buildBlock(_:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock%28_%3A%29

Creates a builder with a block, used for constructing instructions from a variadic list of components.

```APIDOC
## buildBlock(_:)

### Description
Creates a builder with a block. This method is used to construct instructions from a variadic list of components that conform to `InstructionsRepresentable`.

### Method
`static func buildBlock<each I>(_ components: repeat each I) -> Instructions`

### Parameters
#### Generic Parameters
- **I**: A type that conforms to the `InstructionsRepresentable` protocol.

#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **components** (repeat each I) - Required - A variadic list of components conforming to `InstructionsRepresentable`.

### Request Example
```json
{
  "components": [
    {
      "type": "ExampleInstruction1",
      "data": "..."
    },
    {
      "type": "ExampleInstruction2",
      "data": "..."
    }
  ]
}
```

### Response
#### Success Response (200)
- **Instructions** (Instructions) - The constructed `Instructions` object.

#### Response Example
```json
{
  "instructions": {
    "type": "Instructions",
    "components": [
      {
        "type": "ExampleInstruction1",
        "data": "..."
      },
      {
        "type": "ExampleInstruction2",
        "data": "..."
      }
    ]
  }
}
```
```

--------------------------------

### SystemLanguageModel Overview

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

The SystemLanguageModel provides access to an on-device text foundation model for various tasks. You can use the `default` instance for general text generation or initialize it with a specific `UseCase` for specialized tasks like content tagging.

```APIDOC
## Overview

The `SystemLanguageModel` is an on-device text foundation model powering Apple Intelligence. Use `SystemLanguageModel.default` for general text generation. For specialized tasks, initialize with `SystemLanguageModel.UseCase` (e.g., `contentTagging`).

Verify model availability using `SystemLanguageModel.Availability` due to device and settings dependencies (Apple Intelligence support, enabled in Settings).

```swift
struct GenerativeView: View {
    private var model = SystemLanguageModel.default

    var body: some View {
        switch model.availability {
        case .available:
            // Show intelligence UI.
        case .unavailable(.deviceNotEligible):
            // Show alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            // Prompt user to enable Apple Intelligence.
        case .unavailable(.modelNotReady):
            // Model is downloading or unavailable for system reasons.
        case .unavailable(let other):
            // Model unavailable for unknown reason.
        }
    }
}
```
```

--------------------------------

### Define and Use a Weather Tool (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling

Demonstrates defining a custom `Tool` (WeatherTool) for retrieving weather information and integrating it into a LanguageModelSession. The tool's arguments and return type are specified, and it includes error handling for potential issues during execution.

```swift
struct WeatherTool: Tool {
  let name = "getWeather"
  let description = "Retrieve the latest weather information for a city"


  @Generable
  struct Arguments {
      @Guide(description: "The city to get weather information for")
      var city: String
  }


  struct Forecast: Encodable {
      var city: String
      var temperature: Int
  }


  func call(arguments: Arguments) async throws -> String {
      // Get a random temperature value. Use `WeatherKit` to get 
      // a temperature for the city.
      let temperature = Int.random(in: 30...100)
      let formattedResult = """
          The forecast for '\(arguments.city)' is '\(temperature)' \ 
          degrees Fahrenheit. 
          """
      return formattedResult
  }
}


// Create a session with default instructions that guide the requests.
let session = LanguageModelSession(
    tools: [WeatherTool()],
    instructions: "Help the person with getting weather information"
)


// Make a request that compares the temperature between several locations.
let response = try await session.respond(
    to: "Is it hotter in Boston, Wichita, or Pittsburgh?"
)

```

--------------------------------

### Generated Content Initialization

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28properties%3Aid%3A%29

This section details the initialization of generated content using the 'init(properties:id:)' method, which creates a structure with specified properties.

```APIDOC
## init(properties:id:)

### Description
Creates generated content representing a structure with the properties you specify.

### Method
Initializer

### Endpoint
N/A (This is an initializer, not a REST endpoint)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **properties** (KeyValuePairs<String, any ConvertibleToGeneratedContent>) - Required - A collection of key-value pairs representing the properties of the generated content. The order of properties is important for `Generable` types.
- **id** (GenerationID?) - Optional - An optional identifier for the generated content.

### Request Example
```swift
let generatedContent = GeneratedContent(properties: ["key1": "value1", "key2": 123], id: someGenerationID)
```

### Response
#### Success Response (200)
N/A (This is an initializer, not a request that returns a response)

#### Response Example
N/A
```

--------------------------------

### Compile Adapter - Swift

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/compile%28%29

Prepares an adapter before being used with a LanguageModelSession. This method should be called if your adapter has a draft model. It is an asynchronous operation that can throw errors.

```swift
func compile() async throws
```

--------------------------------

### Loading the Model with a Use Case

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

Initializes the `SystemLanguageModel` for a specific use case, such as content tagging, and applies specified guardrails to manage sensitive content.

```APIDOC
## Loading the model with a use case

### `convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)`

Creates a system language model configured for a specific use case and applies guardrails for content moderation.

- `useCase`: A `SystemLanguageModel.UseCase` struct defining the task for prompting.
- `guardrails`: A `SystemLanguageModel.Guardrails` struct to flag sensitive content in model input and output.

### `struct UseCase`

Represents the specific task or scenario for which the language model is being prompted.

### `struct Guardrails`

Defines rules and mechanisms to manage and flag sensitive content from both the input provided to the model and the output it generates.
```

--------------------------------

### Create Prompt Builder with Array of Prompts (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28first%3A%29

This method constructs a prompt builder from an array of prompts. It takes an array of `PromptRepresentable` objects and returns a single `Prompt` object, useful for combining multiple prompts into a sequence.

```swift
static func buildArray(_: [some PromptRepresentable]) -> Prompt
```

--------------------------------

### Foundation Models - Related Builders

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional%28_%3A%29

Utility methods for building various instruction structures within the Foundation Models API.

```APIDOC
## Related Foundation Models Builders

### Description
These are related static methods used for constructing different types of instruction sets.

### Methods

#### `buildArray([some InstructionsRepresentable]) -> Instructions`
Creates a builder with an array of prompts.

#### `buildBlock<each I>(repeat each I) -> Instructions`
Creates a builder with a block of instructions.

#### `buildEither(first: some InstructionsRepresentable) -> Instructions`
Creates a builder with the first component of a conditional instruction.

#### `buildEither(second: some InstructionsRepresentable) -> Instructions`
Creates a builder with the second component of a conditional instruction.

#### `buildExpression(_:)`
Creates a builder with a prompt expression.

#### `buildLimitedAvailability(some InstructionsRepresentable) -> Instructions`
Creates a builder with a limited availability prompt.

### Parameters and Responses
These methods typically take `InstructionsRepresentable` or `Instructions` as parameters and return an `Instructions` object. Specific parameter types and return values are detailed in the full API reference.
```

--------------------------------

### Prompt Building Utilities

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildarray%28_%3A%29

Utility methods for building prompts, including combining blocks, handling optional components, and expressions.

```APIDOC
## Utilities for Prompt Construction

This section describes various utility methods used for building prompts within the Foundation Models API.

### `buildBlock<each P>(repeat each P) -> Prompt`
Creates a builder with a block of prompts.

### `buildEither(first: some PromptRepresentable) -> Prompt`
Creates a builder with the first component of a choice.

### `buildEither(second: some PromptRepresentable) -> Prompt`
Creates a builder with the second component of a choice.

### `buildExpression(_:)`
Creates a builder with a prompt expression.

### `buildLimitedAvailability(some PromptRepresentable) -> Prompt`
Creates a builder with a limited availability prompt.

### `buildOptional(Prompt?) -> Prompt`
Creates a builder with an optional component. Handles cases where a prompt might be null or absent.
```

--------------------------------

### Accessing SystemLanguageModel Availability

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

Demonstrates how to check the availability of the SystemLanguageModel and display different UI elements based on the availability status. This is crucial for providing a graceful user experience when the model is not ready or certain conditions are not met.

```swift
struct GenerativeView: View {
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default


    var body: some View {
        switch model.availability {
        case .available:
            // Show your intelligence UI.
        case .unavailable(.deviceNotEligible):
            // Show an alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            // Ask the person to turn on Apple Intelligence.
        case .unavailable(.modelNotReady):
            // The model isn't ready because it's downloading or because
            // of other system reasons.
        case .unavailable(let other):
            // The model is unavailable for an unknown reason.
        }
    }
}
```

--------------------------------

### Judge In-Game Drink Creation with LanguageModelSession in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Illustrates using LanguageModelSession to judge a player-created drink. A session is initialized with the customer's persona and preferences. A prompt is then constructed to present the ordered drink and the created drink to the model for evaluation and feedback.

```swift
let session = LanguageModelSession {
    """
A conversation between a user and a helpful assistant. This is a fantasy RPG 
game that takes place at Dream Coffee, the beloved coffee shop of the dream 
realm. Your role is to pretend to be the following customer:
\(customer.name): \(customer.picture.imageDescription)
"""
}
let prompt = """
You have just ordered the following drink:
\(customer.coffeeOrder)
The barista has just made you this drink:
\(drink)
Does this drink match your expectations? Do you like it? You must respond 
with helpful feedback for the barista. If you like your drink, give it a 
compliment. If you dislike your drink, politely tell the barista why.
"""
return try await session.respond(to: prompt).content
```

--------------------------------

### Initialize LanguageModelSession with CalendarTool

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Initializes a LanguageModelSession with a CalendarTool to allow characters to access and reference player's on-device calendar events. This integration enables more personalized and natural conversations by referencing real upcoming events.

```swift
if let customer = character as? GeneratedCustomer {
    newSession = LanguageModelSession(
        tools: [CalendarTool(contactName: customer.displayName)],
        instructions: instructions
    )
}

```

--------------------------------

### Foundation Models - Transcript.ToolCall Initializer

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall/init%28id%3Atoolname%3Aarguments%3A%29

Initializes a Transcript.ToolCall object with a unique identifier, tool name, and arguments.

```APIDOC
## Initializer: init(id:toolName:arguments:)

### Description
Initializes a new instance of `Transcript.ToolCall` with the specified identifier, tool name, and arguments.

### Method
Initializer

### Endpoint
N/A (This is an object initializer, not a network endpoint)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let toolCall = Transcript.ToolCall(id: "call-123", toolName: "search", arguments: GeneratedContent(text: "{\"query\": \"apple stock price\"}"))
```

### Response
#### Success Response (200)
N/A (This is an object initializer)

#### Response Example
N/A (This is an object initializer)
```

--------------------------------

### Customize Generation Options with Temperature - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models

This code snippet demonstrates how to customize generation options for a language model session. It specifically shows how to adjust the 'temperature' parameter to influence the creativity of the generated text. This is useful for balancing factual accuracy with imaginative output.

```swift
let options = GenerationOptions(temperature: 2.0)

let session = LanguageModelSession()

let prompt = "Write me a story about coffee."
let response = try await session.respond(
    to: prompt,
    options: options
)
```

--------------------------------

### Configuring Generation Options

Source: https://developer.apple.com/documentation/foundationmodels/index

Control how the Foundation Models generate responses by specifying options such as temperature, token limits, and stop sequences.

```swift
import Foundation

let options = GenerationOptions(
    temperature: 0.7,
    maxTokens: 256,
    stopSequences: ["\n\n"]
)

// Example usage within a session:
// let session = LanguageModelSession()
// let response = try await session.process(prompt: prompt, generationOptions: options)
```

--------------------------------

### Create Builder with Limited Availability using buildLimitedAvailability(_:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

The buildLimitedAvailability(_:) static method creates a builder for instructions that have limited availability. This is useful for handling platform-specific or version-specific instructions. It takes an argument conforming to InstructionsRepresentable.

```swift
static func buildLimitedAvailability(_ instruction: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### SystemLanguageModel.Adapter - Removing obsolete adapters

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter

Removes all obsolete adapters that are no longer compatible with current system models.

```APIDOC
### Removing obsolete adapters

#### Method

- **`static func removeObsoleteAdapters() throws`**

Remove all obsolete adapters that are no longer compatible with current system models.
```

--------------------------------

### Initialize GeneratedContent with Kind and ID (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28kind%3Aid%3A%29

Creates a new GeneratedContent instance using the specified kind and an optional GenerationID. This initializer is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS version 26.0 and later. It takes a GeneratedContent.Kind for the content type and an optional GenerationID.

```swift
init(
    kind: GeneratedContent.Kind,
    id: GenerationID? = nil
)
```

--------------------------------

### Define a Custom Adapter for System Language Model

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Defines a structure for specializing the system language model. This `Adapter` struct is used in conjunction with the model initialization to tailor its capabilities.

```swift
struct Adapter
```

--------------------------------

### Initialize SystemLanguageModel with Use Case and Guardrails

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/init%28usecase%3Aguardrails%3A%29

Creates a system language model for a specific use case with optional guardrails. The `useCase` parameter determines the model's behavior for different prompting scenarios, while `guardrails` helps filter sensitive content. This initializer is available from iOS 26.0 and later.

```swift
convenience init(
    useCase: SystemLanguageModel.UseCase = .general,
    guardrails: SystemLanguageModel.Guardrails = Guardrails.default
)
```

--------------------------------

### Swift: Initialize Transcript.ToolOutput

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooloutput

Initializes a new instance of Transcript.ToolOutput with a unique ID, the tool's name, and an array of transcript segments. This initializer is essential for creating tool output objects.

```swift
init(id: String, toolName: String, segments: [Transcript.Segment])
```

--------------------------------

### Create Builder with Prompt Expression using buildExpression(_:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

The buildExpression(_:) static method creates a builder directly from a prompt expression. This is a fundamental method for incorporating individual prompts into the instruction-building process. It takes a single argument representing the prompt expression.

```swift
static func buildExpression(_ expression: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### Create Builder with Either Component using buildEither(first:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

The buildEither(first:) static method creates a builder that represents the first of two possible instruction components. It takes a single argument that conforms to InstructionsRepresentable and returns an Instructions object.

```swift
static func buildEither(first: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### Create Prompt Builder with Limited Availability (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28first%3A%29

This method creates a prompt builder that is conditionally available. It takes a `PromptRepresentable` object and returns a `Prompt`, allowing for platform-specific or version-specific prompt logic.

```swift
static func buildLimitedAvailability(_: some PromptRepresentable) -> Prompt
```

--------------------------------

### Swift: Create Prompt Builder with buildBlock(_:)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildblock%28_%3A%29

The `buildBlock(_:)` static method creates a prompt builder from a variadic list of prompt-representable components. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS version 26.0 and later. This method is fundamental for composing complex prompts from smaller, reusable parts.

```swift
static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P : PromptRepresentable
```

--------------------------------

### Create Builder with Array of Prompts using buildArray(_:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

The buildArray(_:) static method constructs a builder from an array of instructions. It requires an array of elements conforming to the InstructionsRepresentable protocol. The output is an Instructions object, representing the combined instructions.

```swift
static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions
```

--------------------------------

### Initialize LanguageModelSession with ContactTool

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Initializes a LanguageModelSession using a ContactTool to access the player's contacts. This enables the game to generate game characters with familiar names by finding people born in specific months.

```swift
let session = LanguageModelSession(
    tools: [contactsTool],
    instructions: """
        Use the (contactsTool.name) tool to get a name for a customer.
        """
)

```

--------------------------------

### Initializer: init(name:description:anyOf:)

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init%28name%3Adescription%3Aanyof%3A%29

Creates an 'any-of' schema, which is a union of multiple schemas.

```APIDOC
## Initializer: init(name:description:anyOf:)

### Description
Creates an `any-of` schema, which represents a union of provided schemas.

### Method
`init` (Initializer)

### Endpoint
N/A (This is a Swift initializer for schema creation)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let schema1 = DynamicGenerationSchema(name: "Schema1")
let schema2 = DynamicGenerationSchema(name: "Schema2")
let anyOfSchema = DynamicGenerationSchema(
    name: "MyAnyOfSchema",
    description: "This schema can be either Schema1 or Schema2",
    anyOf: [schema1, schema2]
)
```

### Response
#### Success Response (200)
N/A (This is a Swift initializer, not an API endpoint response)

#### Response Example
N/A
```

--------------------------------

### Loading the Model with an Adapter

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

Allows specialization of the `SystemLanguageModel`'s behavior by integrating a custom-trained adapter. This enables the app to use Foundation Models framework with custom adapters.

```APIDOC
## Loading the model with an adapter

### `com.apple.developer.foundation-model-adapter`

This entitlement is a Boolean value that indicates whether your app is authorized to enable custom adapters for the Foundation Models framework.

### `convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)`

Creates the base version of the model, enhanced with a custom adapter for specialized behavior, and applies specified guardrails.

- `adapter`: A `SystemLanguageModel.Adapter` struct that specializes the system language model for custom use cases.
- `guardrails`: A `SystemLanguageModel.Guardrails` struct to manage sensitive content.
```

--------------------------------

### Create Prompt Builder with Second Component (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28first%3A%29

This method creates a prompt builder representing the second possible component in a conditional prompt. It takes a `PromptRepresentable` object and returns a `Prompt`, complementing the `buildEither(first:)` method.

```swift
static func buildEither(second: some PromptRepresentable) -> Prompt
```

--------------------------------

### Instance Property: temperature

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/temperature

Details the 'temperature' instance property, its purpose, available platforms, and usage.

```APIDOC
## Instance Property: temperature

### Description
Temperature influences the confidence of the model's response. It is an adjustment applied to the probability distribution prior to sampling.

### Method
Instance Property

### Endpoint
N/A

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
var temperature: Double?
```

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A

## Discussion
The value of this property must be a number between `0` and `1` inclusive. A value of `1` results in no adjustment. Values less than `1` will make the probability distribution sharper, with already likely tokens becoming even more likely. Low temperatures manifest as more stable and predictable responses, while high temperatures give the model more creative license. Leaving `temperature` nil lets the system choose a reasonable default on your behalf.

### Platforms
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+
```

--------------------------------

### Initializer: init(arrayOf:minimumElements:maximumElements:)

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init%28arrayof%3Aminimumelements%3Amaximumelements%3A%29

Creates an array schema for Foundation Models. This initializer allows specifying the schema for array elements and optionally setting minimum and maximum element counts.

```APIDOC
## Initializer: init(arrayOf:minimumElements:maximumElements:)

### Description
Creates an array schema for Foundation Models. This initializer allows specifying the schema for array elements and optionally setting minimum and maximum element counts.

### Method
Initializer

### Endpoint
N/A (Initializer for a Swift struct/class)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **itemSchema** (DynamicGenerationSchema) - Required - The schema for the elements within the array.
- **minimumElements** (Int?) - Optional - The minimum number of elements the array must contain.
- **maximumElements** (Int?) - Optional - The maximum number of elements the array can contain.

### Request Example
```swift
let arraySchema = DynamicGenerationSchema.init(
    arrayOf: DynamicGenerationSchema.stringSchema(), // Example: schema for string elements
    minimumElements: 1,
    maximumElements: 10
)
```

### Response
#### Success Response
N/A (Initializers do not return responses in the traditional API sense; they construct an object.)

#### Response Example
N/A
```

--------------------------------

### Structured Reasoning with Generable Type (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model

This Swift code demonstrates how to handle on-device reasoning by defining a `@Generable` struct `ReasonableAnswer` with a dedicated `reasoningSteps` field. This field is intended to capture the model's thought process, preventing it from being inserted into the final answer.

```swift
@Generable
struct ReasonableAnswer {
    // A property the model uses for reasoning.
    var reasoningSteps: String
    
    @Guide(description: "The answer only.")
    var answer: MyCustomGenerableType // Replace with your custom generable type.
}

```

--------------------------------

### Transcript.Entry.toolOutput(_:)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/tooloutput%28_%3A%29

Represents an tool output provided back to the model within the Transcript.Entry.

```APIDOC
## Transcript.Entry.toolOutput(_:)

### Description
An tool output provided back to the model.

### Method
N/A (Enum Case)

### Endpoint
N/A (Enum Case)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A
```

--------------------------------

### Create Prompt Builder with First Component (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28first%3A%29

This method creates a prompt builder that represents the first possible component in a conditional prompt structure. It takes a `PromptRepresentable` as its input and returns a `Prompt` object. This is part of the Swift concurrency and result builder patterns for asynchronous operations.

```swift
static func buildEither(first component: some PromptRepresentable) -> Prompt
```

--------------------------------

### Initialize Foundation Model Response Format with Schema

Source: https://developer.apple.com/documentation/foundationmodels/transcript/responseformat/init%28schema%3A%29

This initializer creates a response format for Foundation Models using a provided schema. It takes a `GenerationSchema` as input and returns a configured response format. This is useful for defining the structure and constraints of model responses.

```swift
init(schema: GenerationSchema)
```

--------------------------------

### SystemLanguageModel.Adapter - AssetError Enum

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter

Defines possible errors related to asset packs for adapters.

```APIDOC
### Asset Errors

- **`enum AssetError`**

(Description for AssetError enum would go here if provided)
```

--------------------------------

### Build Limited Availability Prompt - Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28second%3A%29

Creates a prompt builder for components with limited availability. This function is useful for conditionally including prompt elements that might not be available on all target platforms or OS versions. It is available on Apple platforms.

```swift
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
```

--------------------------------

### Swift DynamicGenerationSchema Initializers

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema

Provides various initializers for creating different types of dynamic schemas. These methods allow for the construction of array, any-of, object, and reference schemas programmatically.

```swift
init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)
init(name:description:anyOf:)
init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])
init(referenceTo: String)
init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])
```

--------------------------------

### Build Optional Prompt - Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28second%3A%29

Creates a prompt builder from an optional prompt component. This function handles the inclusion or exclusion of a prompt element based on whether it is present (non-nil) or absent (nil), allowing for flexible prompt structures. It is available on Apple platforms.

```swift
static func buildOptional(Prompt?) -> Prompt
```

--------------------------------

### Create Builder with a Block using buildBlock<each I>(repeat each I)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

The buildBlock<each I>(repeat each I) static method creates a builder from a block of instructions. This is useful for combining multiple instructions into a single builder. It takes a variadic generic parameter pack `I` where each element must conform to InstructionsRepresentable.

```swift
static func buildBlock<each I>(repeat each I) -> Instructions
```

--------------------------------

### Initialize Foundation Model with ID and Content (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/textsegment/init%28id%3Acontent%3A%29

This initializer creates a Foundation Model instance with a specified content string and an optional unique identifier. If no ID is provided, a UUID string is generated by default. It requires Swift.

```swift
init(
    id: String = UUID().uuidString,
    content: String
)
```

--------------------------------

### Create Builder with Either Component using buildEither(second:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

The buildEither(second:) static method creates a builder that represents the second of two possible instruction components. It takes a single argument that conforms to InstructionsRepresentable and returns an Instructions object.

```swift
static func buildEither(second: some InstructionsRepresentable) -> Instructions
```

--------------------------------

### Foundation Models - buildArray(_:)

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray%28_%3A%29

Creates a builder with an array of prompts using the buildArray function.

```APIDOC
## static func buildArray(_:)

### Description
Creates a builder with an array of prompts.

### Method
Static Function

### Endpoint
N/A (Code-level function)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **instructions** (Array<some InstructionsRepresentable>) - Required - An array of prompts to build.

### Request Example
```swift
// Example usage:
let myArray = [Prompt1(), Prompt2()]
let instructions = FoundationModel.buildArray(myArray)
```

### Response
#### Success Response
- **Instructions** (Type) - The resulting Instructions object.

#### Response Example
```json
{
  "type": "Instructions"
}
```
```

--------------------------------

### Remove Obsolete Adapters

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Removes any outdated adapters from a user's device before downloading a new one. This ensures that only the latest compatible adapter is used, preventing potential conflicts or performance issues.

```swift
SystemLanguageModel.Adapter.removeObsoleteAdapters()

```

--------------------------------

### Initialize Transcript.Response

Source: https://developer.apple.com/documentation/foundationmodels/transcript/response/init%28id%3Aassetids%3Asegments%3A%29

Initializes a Transcript.Response object with optional ID, asset IDs, and transcript segments. The ID defaults to a new UUID if not provided. Requires an array of asset identifiers and transcript segments.

```swift
init(
    id: String = UUID().uuidString,
    assetIDs: [String],
    segments: [Transcript.Segment]
)
```

--------------------------------

### Swift: Implement Top-K Sampling with random(top:seed:)

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/random%28top%3Aseed%3A%29

This Swift code snippet demonstrates the use of the `random(top:seed:)` method for implementing top-k sampling in Foundation Models. It takes an integer `k` for the number of top tokens to consider and an optional `UInt64` seed for deterministic output. Adjusting `k` controls the balance between deterministic and creative generation.

```swift
static func random(
    top k: Int,
    seed: UInt64? = nil
) -> GenerationOptions.SamplingMode
```

--------------------------------

### Manual Implementation of GeneratedContent Mapping

Source: https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent/generatedcontent

This Swift code demonstrates a manual implementation for mapping values onto properties using different names when conforming to `ConvertibleToGeneratedContent`. It shows how to create a `GeneratedContent` object with custom property keys, ensuring symmetry with `init(_:)` if `ConvertibleFromGeneratedContent` is also adopted.

```swift
struct Person: ConvertibleToGeneratedContent {
   var name: String
   var age: Int


   var generatedContent: GeneratedContent {
       GeneratedContent(properties: [
           "firstName": name,
           "ageInYears": age
       ])
   }
}
```

--------------------------------

### LanguageModelSession.GenerationError.refusal(_:_:) API

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal%28_%3A_%3A%29

Details the `refusal` error case for `LanguageModelSession.GenerationError`, indicating when a session refuses a request.

```APIDOC
## LanguageModelSession.GenerationError.refusal(_:_:) 

### Description
An error that happens when the session refuses the request.

### Method
N/A (Enum Case)

### Endpoint
N/A (Enum Case)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (N/A)
This is an enum case representing an error, not an API endpoint response.

#### Response Example
None

### Related Generation Errors

*   `case assetsUnavailable(LanguageModelSession.GenerationError.Context)`: An error that indicates the assets required for the session are unavailable.
*   `case decodingFailure(LanguageModelSession.GenerationError.Context)`: An error that indicates the session failed to deserialize a valid generable type from model output.
*   `case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`: An error that signals the session reached its context window size limit.
*   `case guardrailViolation(LanguageModelSession.GenerationError.Context)`: An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.
*   `case rateLimited(LanguageModelSession.GenerationError.Context)`: An error that indicates your session has been rate limited.
*   `case concurrentRequests(LanguageModelSession.GenerationError.Context)`: An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.
*   `case unsupportedGuide(LanguageModelSession.GenerationError.Context)`: An error that indicates a generation guide with an unsupported pattern was used.
*   `case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`: An error that occurs if the model is prompted to respond in a language that it does not support.

### Related Structures

*   `struct Context`: The context in which the error occurred.
*   `struct Refusal`: A refusal produced by a language model.
```

--------------------------------

### Create Response Format with Type - Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/responseformat

Initializes a ResponseFormat object by specifying the expected content type. This provides a flexible way to define output formats based on Swift types. The system infers the necessary schema from the provided type.

```swift
init<Content>(type: Content.Type)
```

--------------------------------

### Foundation Models Tool Calling API

Source: https://developer.apple.com/documentation/foundationmodels/tool/call%28arguments%3A%29

Details the `call(arguments:)` instance method for tool invocation within Foundation Models.

```APIDOC
## Instance Method

# call(arguments:)

A language model will call this method when it wants to leverage this tool.

### Description
This method is the entry point for a language model to invoke a tool with specific arguments. Errors occurring within this method are wrapped in `LanguageModelSession.ToolCallError`.

### Method
`call(arguments: Self.Arguments) async throws -> Self.Output`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **arguments** (Self.Arguments) - Required - The arguments required by the tool. This type must conform to `ConvertibleFromGeneratedContent`.

### Request Example
```json
{
  "arguments": { ... } 
}
```

### Response
#### Success Response (200)
- **output** (Self.Output) - The output produced by the tool, which the language model can use for further reasoning. This type must conform to `PromptRepresentable`.

#### Response Example
```json
{
  "output": { ... }
}
```

### Associated Types
- **Arguments**: `associatedtype Arguments : ConvertibleFromGeneratedContent` - The arguments that this tool should accept.
- **Output**: `associatedtype Output : PromptRepresentable` - The output that this tool produces for the language model to reason about in subsequent interactions.

### See Also
- Invoking a tool
- Expanding generation with tool calling
```

--------------------------------

### Prompt Model for Content Tags (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags

This code shows how to prompt the content tagging model with a given text and specify the desired output type as `ContentTaggingResult.self`. The model will then return tags associated with the input text, such as 'outdoor activity' or 'beach'.

```swift
let prompt = """
    Today we had a lovely picnic with friends at the beach.
    """
let response = try await session.respond(
    to: prompt,
    generating: ContentTaggingResult.self
)
```

--------------------------------

### Related Transcript.Entry Cases

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/tooloutput%28_%3A%29

Provides information on other related cases within Transcript.Entry, such as instructions, prompt, response, and toolCalls.

```APIDOC
## Related Transcript.Entry Cases

### `case instructions(Transcript.Instructions)`

#### Description
Instructions, typically provided by you, the developer.

### `case prompt(Transcript.Prompt)`

#### Description
A prompt, typically sourced from an end user.

### `case response(Transcript.Response)`

#### Description
A response from the model.

### `case toolCalls(Transcript.ToolCalls)`

#### Description
A tool call containing a tool name and the arguments to invoke it with.
```

--------------------------------

### Tool Properties: Name, Description, and Schema

Source: https://developer.apple.com/documentation/foundationmodels/tool

Defines the essential properties for a `Tool`: `name` (a unique identifier), `description` (natural language explanation), and `parameters` (a `GenerationSchema` for argument validation).

```swift
var description: String
var name: String
var parameters: GenerationSchema
```

--------------------------------

### Swift: Respond to a prompt with specified generation type

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28generating%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

This Swift code defines the `respond` instance method for generating content. It takes the desired content type, schema inclusion option, generation options, and a prompt as input. The method is available on iOS, iPadOS, macOS, and visionOS versions 26.0 and later.

```swift
@discardableResult nonisolated(nonsending)
final func respond<Content>(
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
) async throws -> LanguageModelSession.Response<Content> where Content : Generable
```

--------------------------------

### Create Prompt Expression Builder (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildexpression%28_%3A%29

The `buildExpression(_:)` static method in Swift is used to create a prompt expression. It takes a `Prompt` object as input and returns a `Prompt` object representing the built expression. This functionality is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS versions 26.0 and later.

```swift
static func buildExpression(_ expression: Prompt) -> Prompt
```

--------------------------------

### Implementing a Custom Tool for Model Interaction

Source: https://developer.apple.com/documentation/foundationmodels/index

Create custom tools that the Foundation Models framework can call to perform specific tasks, such as searching a database or interacting with app services.

```swift
import Foundation

struct SearchDatabaseTool: Tool {
    func execute(query: String) async throws -> String {
        // Implement your database search logic here
        return "Results for \(query): ..."
    }
}

// Example usage:
// let tool = SearchDatabaseTool()
// let session = LanguageModelSession(tools: [tool])
// let response = try await session.process(prompt: "Search for information about the weather.")
```

--------------------------------

### Accessing General Use Case - Swift

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase/general

This code snippet shows how to access the static property 'general' which represents the default use case for general prompting with SystemLanguageModel. This property is part of the SystemLanguageModel.UseCase type and is available across various Apple platforms.

```swift
static let general: SystemLanguageModel.UseCase
```

--------------------------------

### Build Prompt from Expression in Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder

Creates a prompt from a single expression that conforms to `PromptRepresentable`. This is a fundamental method for incorporating individual prompt elements.

```swift
static func buildExpression(_ expression: some PromptRepresentable) -> Prompt
```

--------------------------------

### Respond to Prompt - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28to%3Agenerating%3Aincludeschemainprompt%3Aoptions%3A%29-13kji

This Swift method generates a `Generable` object in response to a text prompt. It allows specifying the desired output type, whether to include the schema in the prompt, and generation options for controlling token sampling. The method returns a `LanguageModelSession.Response` of the specified `Content` type.

```swift
@discardableResult nonisolated(nonsending)
final func respond<Content>(
    to prompt: String,
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
) async throws -> LanguageModelSession.Response<Content> where Content : Generable
```

--------------------------------

### Create Builder with Block using buildBlock(_:) - Swift

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock%28_%3A%29

The `buildBlock(_:)` static method creates a builder that incorporates a block of instructions. It is available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+. This function takes a variadic list of components conforming to `InstructionsRepresentable` and returns an `Instructions` object.

```swift
static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I : InstructionsRepresentable
```

--------------------------------

### Check System Readiness with isAvailable (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/isavailable

The 'isAvailable' property is a convenience getter that returns a Boolean value indicating whether the system is entirely ready to use the Foundation Models. It has no direct inputs or outputs other than its Boolean return value and requires no specific dependencies beyond the Foundation Models framework itself.

```swift
final var isAvailable: Bool { get }
```

--------------------------------

### Define SystemLanguageModel.UseCase Struct

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase

Defines the 'UseCase' struct which represents a specific use case for interacting with Foundation Models. This is a fundamental type for initializing model interactions.

```swift
struct UseCase
```

--------------------------------

### Build Prompt with Limited Availability in Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder

Constructs a prompt that might have limited availability. This is useful for features that are not present on all platforms or OS versions.

```swift
static func buildLimitedAvailability(_ component: some PromptRepresentable) -> Prompt
```

--------------------------------

### Instance Property: instructionsRepresentation

Source: https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation

This section describes the `instructionsRepresentation` instance property of the InstructionsRepresentable protocol. It returns an instance that represents the instructions.

```APIDOC
## Instance Property: instructionsRepresentation

### Description
An instance that represents the instructions.

### Availability
iOS 26.0+<br>iPadOS 26.0+<br>Mac Catalyst 26.0+<br>macOS 26.0+<br>visionOS 26.0+

### Declaration
```swift
@InstructionsBuilder
var instructionsRepresentation: Instructions { get }
```

### Default Implementations
`InstructionsRepresentable` provides a default implementation for `instructionsRepresentation`.
```

--------------------------------

### Tool Implementations: name

Source: https://developer.apple.com/documentation/foundationmodels/tool/name

Details on the 'name' property within the context of Tool Implementations. It's a required string that must uniquely identify the tool.

```APIDOC
## Default Implementations

### Tool Implementations

`var name: String`
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.

**Required**.
```

--------------------------------

### Creating a session from a transcript

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

APIs for creating a session by rehydrating from a previous transcript.

```APIDOC
### Creating a session from a transcript

`convenience init(model: SystemLanguageModel, tools: [any Tool], transcript: Transcript)`
Start a session by rehydrating from a transcript.

`struct Transcript`
A linear history of entries that reflect an interaction with a session.
```

--------------------------------

### LanguageModelFeedback Initializer

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/init%28category%3Aexplanation%3A%29

Initializes a new issue for LanguageModelFeedback with a specified category and an optional explanation.

```APIDOC
## init(category:explanation:)

### Description
Creates a new issue for LanguageModelFeedback.

### Method
Initializer

### Endpoint
N/A (Initializers are not endpoints)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let issue = LanguageModelFeedback.Issue(category: .accuracy, explanation: "The model provided an inaccurate response.")
```

### Response
#### Success Response (200)
N/A (Initializers do not return responses in the typical API sense)

#### Response Example
N/A
```

--------------------------------

### Interacting with the On-Device Language Model

Source: https://developer.apple.com/documentation/foundationmodels/index

Initiate a session with the on-device language model to perform text generation tasks. This involves creating a session and processing prompts.

```swift
import Foundation

func generateText(promptContent: String) async {
    do {
        let session = LanguageModelSession()
        let prompt = Prompt(text: promptContent)
        let response = try await session.process(prompt: prompt)
        print(response.text)
    } catch {
        print("Error generating text: \(error)")
    }
}

// Example usage:
// await generateText(promptContent: "Write a short poem about the ocean.")
```

--------------------------------

### Swift: Converting conditional prompting to programming logic

Source: https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model

This Swift code snippet illustrates how to replace complex conditional statements within a prompt by using programmatic logic (switch statements) to customize the instructions based on context, improving model efficiency and reducing confusion.

```swift
var customGreeting = ""
switch role {
case .bard:
    customGreeting = "This guest is a bard. Ask if they’re willing to play music for the inn tonight."
case .soldier:
    customGreeting = "This guest is a soldier. Ask if there’s been any dangerous activity in the area."
case .sorcerer:
    customGreeting = "This guest is a sorcerer. Comment on their magical appearance."
default:
    customGreeting = "This guest is a weary traveler."
}


let instructions = """
    You are a friendly inn keeper. Generate a greeting to a new guest that walks in the door.
    \(customGreeting)
    There is one single and one double room available.
    """

```

--------------------------------

### Foundation Models Initializer

Source: https://developer.apple.com/documentation/foundationmodels/transcript/response/init%28id%3Aassetids%3Asegments%3A%29

Details the `init(id:assetIDs:segments:)` initializer for the Foundation Models API, including platform availability and parameter descriptions.

```APIDOC
## Initialize Foundation Model

### Description
Initializes a new instance of Foundation Models with a unique identifier, a list of asset identifiers, and a collection of transcript segments.

### Method
`init`

### Endpoint
N/A (This is an initializer, not a network endpoint)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
*   **id** (String) - Optional - A unique identifier for the model instance. Defaults to a new UUID.
*   **assetIDs** ([String]) - Required - An array of strings representing the identifiers of the assets associated with the model.
*   **segments** ([Transcript.Segment]) - Required - An array of `Transcript.Segment` objects representing the segmented transcript data.

### Request Example
```swift
let segments: [Transcript.Segment] = [...] // Your array of segments
let model = FoundationModel(
    assetIDs: ["asset1", "asset2"],
    segments: segments
)
```

### Response
#### Success Response (Initialization)
An initialized `FoundationModel` object.

#### Response Example
```swift
// Swift object initialization, no JSON response
```

### Platform Availability
*   iOS 26.0+
*   iPadOS 26.0+
*   Mac Catalyst 26.0+
*   macOS 26.0+
*   visionOS 26.0+
```

--------------------------------

### Swift Custom Tool for Database Search with Tool Calling

Source: https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling

Defines a custom tool named 'searchBreadDatabase' in Swift that accepts search terms and a limit for recipes. It conforms to the 'Tool' protocol and includes a 'call' method to retrieve recipes from a database. The tool uses '@Generable' for argument definition, allowing for structured input with descriptions.

```swift
struct BreadDatabaseTool: Tool {
    let name = "searchBreadDatabase"
    let description = "Searches a local database for bread recipes."


    @Generable
    struct Arguments {
        @Guide(description: "The type of bread to search for")
        var searchTerm: String
        @Guide(description: "The number of recipes to get", .range(1...6))
        var limit: Int
    }


    struct Recipe {
        var name: String
        var description: String
        var link: URL
    }
    
    func call(arguments: Arguments) async throws -> [String] {
        var recipes: [Recipe] = []
        
        // Put your code here to retrieve a list of recipes from your database.
        
        let formattedRecipes = recipes.map {
            "Recipe for '\($0.name)': \($0.description) Link: \($0.link)"
        }
        return formattedRecipes
    }
}

```

--------------------------------

### Build Array Prompt - Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither%28second%3A%29

Creates a prompt builder containing an array of prompts. This function is used to group multiple prompt components into a single array, facilitating the construction of sequential or related prompt elements. It is available on Apple platforms.

```swift
static func buildArray([some PromptRepresentable]) -> Prompt
```

--------------------------------

### Accessing Tool Description in Swift

Source: https://developer.apple.com/documentation/foundationmodels/tool/description

Retrieves a natural language description of when and how to use a tool within the Foundation Models framework. This property is essential for understanding the tool's functionality and intended use cases. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS from version 26.0 onwards.

```swift
var description: String { get }
```

--------------------------------

### GenerationSchema Structure

Source: https://developer.apple.com/documentation/foundationmodels/generationschema

This section provides details on the GenerationSchema structure and its initializers.

```APIDOC
## GenerationSchema
A type that describes the properties of an object and any guides on their values.

Available in iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+

```swift
struct GenerationSchema
```

### Overview
Generation schemas guide the output of a `SystemLanguageModel` to deterministically ensure the output is in the desired format.

### Creating a generation schema

- `init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws`
  Creates a schema by providing an array of dynamic schemas.
- `init(type:description:anyOf:)`
  Creates a schema for a string enumeration.
- `init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])`
  Creates a schema by providing an array of properties.

### Properties

- `struct Property`
  A property that belongs to a generation schema.

### Debug Description

- `var debugDescription: String`
  A string representation of the debug description.

### Schema Errors

- `enum SchemaError`
  An error that occurs when there is a problem creating a generation schema.

### Getting the schema

- `static var generationSchema: GenerationSchema`
  An instance of the generation schema.
```

--------------------------------

### Display Transcript Entries in SwiftUI

Source: https://developer.apple.com/documentation/foundationmodels/transcript

Demonstrates how to create a SwiftUI `View` called `HistoryView` that displays the entries of a `LanguageModelSession`'s transcript. It iterates through each `entry` in the `session.transcript` and renders a specific view based on the entry's type (instructions, prompt, tool calls, tool output, or response).

```swift
struct HistoryView: View {
    let session: LanguageModelSession


    var body: some View {
        ScrollView {
            ForEach(session.transcript) { entry in
                switch entry {
                case let .instructions(instructions):
                    MyInstructionsView(instructions)
                case let .prompt(prompt)
                    MyPromptView(prompt)
                case let .toolCalls(toolCalls):
                    MyToolCallsView(toolCalls)
                case let .toolOutput(toolOutput):
                    MyToolOutputView(toolOutput)
                case let .response(response):
                    MyResponseView(response)
                }
            }
        }
    }
}
```

--------------------------------

### Define a Tool Definition - Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition

Defines how to create a ToolDefinition using its name, description, and generation schema, or by using an existing Tool. This structure is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS from version 26.0 onwards.

```swift
struct ToolDefinition
init(name: String, description: String, parameters: GenerationSchema)
init(tool: some Tool)
```

--------------------------------

### Check Foundation Model Availability in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models

This code snippet demonstrates how to check the availability of the system language model using the `SystemLanguageModel.default` property. It uses a switch statement to handle different availability states, providing appropriate UI for each case. This is crucial for ensuring a seamless user experience by offering fallback options when the model is not available.

```swift
import SwiftUI
import FoundationModels

struct GenerativeView: View {
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default


    var body: some View {
        switch model.availability {
        case .available:
            // Show your intelligence UI.
            Text("Model is available!")
        case .unavailable(.deviceNotEligible):
            // Show an alternative UI.
            Text("Device not eligible for Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            // Ask the person to turn on Apple Intelligence.
            Text("Please enable Apple Intelligence in Settings.")
        case .unavailable(.modelNotReady):
            // The model isn't ready because it's downloading or because of other system reasons.
            Text("Model is not ready. Please try again later.")
        case .unavailable(let other):
            // The model is unavailable for an unknown reason.
            Text("Model is unavailable for an unknown reason.")
        }
    }
}
```

--------------------------------

### GenerationGuide.minimum(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/minimum%28_%3A%29

Enforces an inclusive minimum value for a generated `Decimal` type. This is useful for setting lower bounds on numerical values, such as ensuring a character's level is at least 1.

```APIDOC
## POST /generation/guide/minimum

### Description
Enforces a minimum value for a generated `Decimal`.

### Method
POST

### Endpoint
`/generation/guide/minimum`

### Parameters
#### Request Body
- **value** (Decimal) - Required - The minimum value to enforce.

### Request Example
```json
{
  "value": 1.0
}
```

### Response
#### Success Response (200)
- **generationGuide** (GenerationGuide<Decimal>) - A GenerationGuide object configured with the minimum value.

#### Response Example
```json
{
  "generationGuide": {
    "type": "Decimal",
    "minimum": 1.0
  }
}
```
```

--------------------------------

### GeneratedContent.Kind Swift Initializer

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift

This Swift code snippet demonstrates how to initialize a GeneratedContent instance using a specific kind and an optional GenerationID. This is essential for creating new content objects within the FoundationModels framework.

```swift
init(kind: GeneratedContent.Kind, id: GenerationID?)
```

--------------------------------

### Define Decimal Range Constraint for GenerationGuide

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/range%28_%3A%29

This Swift code demonstrates how to use the `range(_:)` method to create a `GenerationGuide` that enforces an inclusive range for `Decimal` values. This is useful for ensuring generated data stays within specified bounds, like setting a character's level between 1 and 100.

```swift
static func range(_ range: ClosedRange<Decimal>) -> GenerationGuide<Decimal>
```

```swift
@Generable
struct GameCharacter {
    @Guide(description: "A creative name appropriate for a fantasy RPG character")
    var name: String


    @Guide(description: "A level for the character", .range(1...100))
    var level: Int
}
```

--------------------------------

### GeneratedContent Initializer

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28properties%3Aid%3Auniquingkeyswith%3A%29

Creates new generated content from a sequence of key-value pairs, using a combining closure to resolve duplicate keys.

```APIDOC
## init(properties:id:uniquingKeysWith:)

### Description
Creates new generated content from the key-value pairs in the given sequence, using a combining closure to determine the value for any duplicate keys.

### Method
`init` (Initializer)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **properties** (S where S : Sequence, S.Element == (String, any ConvertibleToGeneratedContent)) - Required - A sequence of key-value pairs to use for the new content.
- **id** (GenerationID?) - Optional - A unique id associated with `GeneratedContent`.
- **uniquingKeysWith** ((GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent) - Required - A closure that is called with the values to resolve any duplicates keys that are encountered. The closure returns the desired value for the final content.

### Request Example
```swift
let content = GeneratedContent(
  properties: [("name", "John"), ("name", "Jane"), ("married", true)],
  uniquingKeysWith: { (first, _) in first }
)
```

### Response
#### Success Response (200)
Represents the created `GeneratedContent` object.

#### Response Example
```json
{
  "example": "GeneratedContent([\"name\": \"John\", \"married\": true])"
}
```

### Discussion
The order of properties is important. For `Generable` types, the order must match the order properties in the types `schema`. You use this initializer to create generated content when you have a sequence of key-value tuples that might have duplicate keys. As the content is built, the initializer calls the `combine` closure with the current and new values for any duplicate keys. Pass a closure as `combine` that returns the value to use in the resulting content: The closure can choose between the two values, combine them to produce a new value, or even throw an error.

### See Also
- `init(properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>, id: GenerationID?)`
```

--------------------------------

### Defining Prompt Use Cases with UseCase

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

Introduces the UseCase struct for representing specific prompting scenarios. This type helps in structuring the input and context provided to generative models, ensuring clarity and relevance for the desired output. It is a fundamental part of defining how to interact with the models.

```swift
struct UseCase
A type that represents the use case for prompting.
```

--------------------------------

### GenerationOptions Properties

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions

Properties to configure response tokens, sampling mode, and temperature.

```APIDOC
## `GenerationOptions` Properties

### Description
Properties that control how the model generates its response, including token limits, sampling strategies, and response confidence.

### Method
* Property Access (Implicit)

### Endpoint
* Not applicable (struct properties)

### Parameters
#### Path Parameters
* None

#### Query Parameters
* None

#### Request Body
* None

### Request Example
```json
{
  "maximumResponseTokens": 150,
  "sampling": {"value": "top_p", "parameter": 0.9},
  "temperature": 0.8
}
```

### Response
#### Success Response (200)
* `maximumResponseTokens` (Int?) - The maximum number of tokens the model is allowed to produce in its response.
* `sampling` (GenerationOptions.SamplingMode?) - A sampling strategy for how the model picks tokens when generating a response.
* `temperature` (Double?) - Temperature influences the confidence of the model's response.

#### Response Example
```json
{
  "maximumResponseTokens": 150,
  "sampling": {"value": "top_p", "parameter": 0.9},
  "temperature": 0.8
}
```
```

--------------------------------

### prewarm(promptPrefix:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/prewarm%28promptprefix%3A%29

Loads session resources into memory and optionally caches a prompt prefix to reduce latency. Use this when you anticipate immediate user interaction with the session.

```APIDOC
## prewarm(promptPrefix:)

### Description
Loads the resources required for this session into memory, and optionally caches a prefix of your prompt to reduce request latency.

### Method
`func`

### Endpoint
N/A (Instance Method)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
* **promptPrefix** (Prompt?) - Optional - A prefix of your prompt to cache for reduced latency.

### Request Example
```swift
// Assuming 'session' is an instance of a Foundation Model session
session.prewarm(promptPrefix: "User input prefix") 
```

### Response
This method does not return a value directly. Its effect is to preload resources and potentially cache the prompt prefix.

#### Success Response (N/A)
N/A

#### Response Example
N/A

## Discussion
Use this method when you know a person will launch and interact with your session within a few seconds to preload the required session resources. For example, you might call this method when a person begins typing into a text field.

If you have a prefix for a future prompt, passing it to this method allows the system to process the prompt eagerly and reduce latency for the future request.

**Important**

* Only use this method when you have at least one second before calling a respond method, like `respond(to:options:)` or `streamResponse(to:options:)`.
* Calling this method doesn’t guarantee that the system loads your resources immediately, particularly if your app is running in the background or the system is under load.
```

--------------------------------

### Stream Response to Prompt in Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28to%3Aoptions%3A%29

This Swift code snippet demonstrates how to use the `streamResponse(to:options:)` method to produce a stream of responses to a given prompt. It takes a `Prompt` object and optional `GenerationOptions` as input and returns a `LanguageModelSession.ResponseStream<String>`.

```swift
final func streamResponse(
    to prompt: Prompt,
    options: GenerationOptions = GenerationOptions()
) -> sending LanguageModelSession.ResponseStream<String>
```

--------------------------------

### LanguageModelSession.ResponseStream.Snapshot.content

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/content

Retrieves the content of the response stream snapshot.

```APIDOC
## GET /websites/developer_apple_foundationmodels/content

### Description
This endpoint retrieves the content of the response stream snapshot.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/content

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
- **content** (Content.PartiallyGenerated) - The content of the response.

#### Response Example
```json
{
  "content": {
    "text": "This is the response content."
  }
}
```
```

--------------------------------

### Inspect Session Transcript (SwiftUI)

Source: https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling

Demonstrates how to inspect the session's `transcript` property in a SwiftUI view to track tool calls and their outcomes. This is useful for debugging and visualizing the interaction history between the model and its tools.

```swift
struct MyHistoryView: View {


    @State
    var session = LanguageModelSession(
        tools: [BreadDatabaseTool()]
    )
    
    var body: some View {
        List(session.transcript) { entry in
            switch entry {
            case .instructions(let instructions):
                // Display the instructions the model uses.
            case .prompt(let prompt):
                // Display the prompt made to the model.
            case .toolCall(let call):
                // Display the call details for a tool, like the tool name and arguments.        
            case .toolOutput(let output):
                // Display the output that a tool provides back to the model.        
            case .response(let response):
                // Display the response from the model.
            }
        }.task {
            do {
                try await session.respond(to: "Find a milk bread recipe.")
            } catch let error {
                // Handle the error.
            }
        }
    }
    
}


```

--------------------------------

### Initialize Transcript.ToolCall

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall

Initializes a new tool call instance with a unique ID, the name of the tool to be invoked, and the arguments to be passed to it. This is the primary method for creating a tool call object.

```swift
init(id: String, toolName: String, arguments: GeneratedContent)
```

--------------------------------

### LanguageModelSession Overview

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

Provides an overview of the LanguageModelSession, explaining its purpose in maintaining context and managing interactions with language models.

```APIDOC
## Overview
A session is a single context that you use to generate content with, and maintains state between requests. You can reuse the existing instance or create a new one each time you call the model. When creating a session, provide instructions that tells the model what its role is and provide guidance on how to respond.

```swift
let instructions = """
    You are a motivational workout coach that provides quotes to inspire \ 
    and motivate athletes.
    """
let session = LanguageModelSession(instructions: instructions)
let prompt = "Generate a motivational quote for my next workout."
let response = try await session.respond(to: prompt)
```

The framework records each call to the model in a `Transcript` that includes all prompts and responses. If your session exceeds the available context size, it throws `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`.

When you perform a task that needs a larger context size, split the task into smaller steps and run each of them in a new `LanguageModelSession`. For example, to generate a summary for a long article on device:
  1. Separate the article into smaller sections.
  2. Summarize each section with a new session instance.
  3. Combine the sections.
  4. Repeat the steps until you get a summary with the size you want, and consider adding the summary to the prompt so it conveys the contextual information.

Use Instruments to analyze token consumption while your app is running and to look for opportunities to improve performance, like with `prewarm(promptPrefix:)`. To profile your app with Instruments:
  1. Open your Xcode project and choose Product > Profile to launch Instruments.
  2. Select the Blank template, then click Choose.
  3. In Instruments, click “+ Instrument” to open the instruments library.
  4. Choose the Foundation Models instrument from the list.
  5. Choose File > Record Trace. This launches your app and starts a recording session to observe token usage from your app’s model interactions.

Because some generation tasks can be resource intensive, consider profiling your app with other instruments — like Activity Monitor and Power Profiler — to identify where your app might be using more system resources than expected.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.
```

--------------------------------

### Swift: Check SystemLanguageModel Availability

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/available

This snippet demonstrates how to check for the availability of the SystemLanguageModel using Swift. It shows the 'available' case, indicating the system is ready for requests. This is relevant for integrating language model functionalities into applications.

```swift
case available
```

--------------------------------

### Creating Feedback

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback

This section details the structures and functions used for creating and logging feedback related to language models.

```APIDOC
## Topics

### Creating feedback

`struct Issue`
An issue with the model’s response.

`enum Sentiment`
A sentiment regarding the model’s response.

`func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data`
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.
```

--------------------------------

### ConvertibleFromGeneratedContent Protocol

Source: https://developer.apple.com/documentation/foundationmodels/convertiblefromgeneratedcontent

This section details the ConvertibleFromGeneratedContent protocol, including its initializer and inherited relationships.

```APIDOC
## Protocol: ConvertibleFromGeneratedContent

### Description
A type that can be initialized from generated content.

Available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+.

```swift
protocol ConvertibleFromGeneratedContent : SendableMetatype
```

### Topics

#### Creating a convertible

`init(GeneratedContent) throws`
Creates an instance from content generated by a model.

**Required**

### Relationships

#### Inherits From

* `SendableMetatype`

#### Inherited By

* `Generable`

### Conforming Types

* `GeneratedContent`
```

--------------------------------

### Checking Model Availability

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

Provides methods to check if the `SystemLanguageModel` is currently available on the device and ready for use, considering various system and user-enabled factors.

```APIDOC
## Checking model availability

### `var isAvailable: Bool`

A convenience property that returns `true` if the system is entirely ready to use the model, and `false` otherwise.

### `var availability: SystemLanguageModel.Availability`

Provides detailed information about the availability status of the language model.

### `enum Availability`

An enumeration that defines the possible availability states for a specific system language model, including various reasons for unavailability.
```

--------------------------------

### Initializer: init(tool:underlyingError:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror/init%28tool%3Aunderlyingerror%3A%29

Creates an instance of a tool call error, specifying the tool that caused the error and the underlying error.

```APIDOC
## init(tool:underlyingError:)

### Description
Creates a tool call error.

### Method
`init` (initializer)

### Endpoint
N/A (Initializes a Swift struct/class)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let error = LanguageModelSession.ToolCallError(tool: myTool, underlyingError: someError)
```

### Response
#### Success Response
N/A (Initializes an object)

#### Response Example
N/A

## Parameters 

`tool`
    
The tool that produced the error.

`underlyingError`
    
The underlying error that was thrown during a tool call.
```

--------------------------------

### LanguageModelSession.ResponseStream.Snapshot.rawContent

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/content

Retrieves the raw content of the response stream snapshot.

```APIDOC
## GET /websites/developer_apple_foundationmodels/rawContent

### Description
This endpoint retrieves the raw content of the response stream snapshot.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/rawContent

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
- **rawContent** (GeneratedContent) - The raw content of the response.

#### Response Example
```json
{
  "rawContent": {
    "text": "This is the raw response content."
  }
}
```
```

--------------------------------

### SystemLanguageModel.Availability.unavailable(_:)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailable%28_%3A%29

Represents the state where the system is not ready to handle requests. This case is associated with a reason for unavailability.

```APIDOC
## SystemLanguageModel.Availability.unavailable(_:)

### Description
Indicates that the system is not ready for requests.

### Method
N/A (Enum Case)

### Endpoint
N/A

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (N/A)
None

#### Response Example
None

### Related Cases
- `available`: The system is ready for making requests.

### Associated Types
- `SystemLanguageModel.Availability.UnavailableReason`: Enum representing the reason for unavailability.
```

--------------------------------

### SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/devicenoteligible

This documentation describes the `deviceNotEligible` case for `SystemLanguageModel.Availability.UnavailableReason`, indicating that the device does not support Apple Intelligence.

```APIDOC
## SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible

### Description
The device does not support Apple Intelligence.

### Availability
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+

### Case
```swift
case deviceNotEligible
```

### See Also
#### Getting the unavailable reasons
* `case appleIntelligenceNotEnabled`: Apple Intelligence is not enabled on the system.
* `case modelNotReady`: The model(s) aren’t available on the user’s device.
```

--------------------------------

### DynamicGenerationSchema Overview

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema

Provides an overview of the DynamicGenerationSchema, including its purpose and how schema references are resolved.

```APIDOC
## DynamicGenerationSchema

### Description
The dynamic counterpart to the generation schema type that you use to construct schemas at runtime. An individual schema may reference other schemas by name, and references are resolved when converting a set of dynamic schemas into a `GenerationSchema`.

### Topics

#### Creating a dynamic schema
- `init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`: Creates an array schema.
- `init(name:description:anyOf:)`: Creates an any-of schema.
- `init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`: Creates an object schema.
- `init(referenceTo: String)`: Creates an refrence schema.
- `init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])`: Creates a schema from a generable type and guides.

### Nested Types

#### struct Property

A property that belongs to a dynamic generation schema.

### Conformance

- `Sendable`
- `SendableMetatype`
```

--------------------------------

### DynamicGenerationSchema.Property Initializer

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/property/init%28name%3Adescription%3Aschema%3Aisoptional%3A%29

This section details the initializer for creating a property that references a dynamic schema.

```APIDOC
## DynamicGenerationSchema.Property Initializer

### Description
Creates a property referencing a dynamic schema.

### Method
`init(name:description:schema:isOptional:)`

### Endpoint
N/A (This is a constructor for a class)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
```swift
init(
    name: String,
    description: String? = nil,
    schema: DynamicGenerationSchema,
    isOptional: Bool = false
)
```

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A

### Parameters Details:

`name` (String) - Required - A name for this property.

`description` (String?) - Optional - An optional natural language description of this property’s contents.

`schema` (DynamicGenerationSchema) - Required - A schema representing the type this property contains.

`isOptional` (Bool) - Optional (defaults to false) - Determines if this property is required or not.
```

--------------------------------

### Dynamically Tag Landmark Descriptions

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

Automatically generates relevant hashtags for landmark descriptions using a content tagging model. This helps users quickly understand the characteristics of a destination.

```swift
let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)


.task {
    if !contentTaggingModel.isAvailable { return }
    do {
        let session = LanguageModelSession(model: contentTaggingModel)
        let stream = session.streamResponse(
            to: landmark.description,
            generating: TaggingResponse.self,
            options: GenerationOptions(sampling: .greedy)
        )
        for try await newTags in stream {
            generatedTags = newTags.content
        }
    } catch {
        Logging.general.error("\(error.localizedDescription)")
    }
}
```

--------------------------------

### AssetError Cases for SystemLanguageModel Adapters

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror

Illustrates the specific error cases within the AssetError enumeration for SystemLanguageModel adapters. These cases indicate reasons such as incompatible adapters, invalid names, or malformed asset files, each associated with a context object.

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```

--------------------------------

### SystemLanguageModel.Availability.unavailable(SystemLanguageModel.Availability.UnavailableReason)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/available

Indicates that the system is not ready for requests, providing a reason for unavailability.

```APIDOC
## SystemLanguageModel.Availability.unavailable(SystemLanguageModel.Availability.UnavailableReason)

### Description
Indicates that the system is not ready for requests.

### Method
N/A (Property)

### Endpoint
N/A

### Parameters
N/A

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A

### See Also
- `enum UnavailableReason`: The unavailable reason.
```

--------------------------------

### Build Prompt from Block in Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder

Constructs a prompt from a variadic list of `PromptRepresentable` types. This method is part of the `PromptBuilder` result builder.

```swift
static func buildBlock<each P>(_ repeat each P) -> Prompt where repeat each P: PromptRepresentable
```

--------------------------------

### Swift: Respond to a prompt with a specific schema

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond%28generating%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

This Swift function generates a `GeneratedContent` type as a response to a prompt, taking into account a provided `GenerationSchema`. It allows for explicit control over schema inclusion and generation options.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
```

--------------------------------

### SystemLanguageModel.isCompatible(_:)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/iscompatible%28_%3A%29

Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.

```APIDOC
## SystemLanguageModel.isCompatible(_:)

### Description
Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.

### Method
`static func isCompatible(_ assetPack: AssetPack) -> Bool`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```json
{
  "assetPack": "your_asset_pack_object"
}
```

### Response
#### Success Response (200)
- **Bool** (Boolean) - `true` if the asset pack is compatible, `false` otherwise.

#### Response Example
```json
{
  "isCompatible": true
}
```

## Discussion
Use this check when choosing an adapter asset pack to download. This check only validates the asset pack name and metadata, so initializing the adapter with `init(name:)` — or loading the adapter onto the base model with `init(adapter:guardrails:)` — may throw errors if the adapter has a compatibility issue despite having correct metadata.

## See Also
### Checking compatibility
`static func compatibleAdapterIdentifiers(name: String) -> [String]`
Get all compatible adapter identifiers compatible with current system models.
```

--------------------------------

### ToolDefinition API

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition

This section details the initializers and properties for the ToolDefinition struct.

```APIDOC
## Transcript.ToolDefinition

A definition of a tool.

### Description
Represents a definition of a tool that can be used with foundation models.

### Initializers

#### `init(name: String, description: String, parameters: GenerationSchema)`
Initializes a new ToolDefinition with a name, description, and parameter schema.

#### `init(tool: some Tool)`
Initializes a new ToolDefinition from an existing Tool object.

### Properties

#### `description`
- **Type**: `String`
- **Description**: A description of how and when to use the tool.

#### `name`
- **Type**: `String`
- **Description**: The tool's name.
```

--------------------------------

### Swift: Generating a Response with a Schema

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response

Asynchronously generates a `GeneratedContent` response based on a provided schema, prompt, and generation options. It includes an option to incorporate the schema into the prompt. Returns a `LanguageModelSession.Response<GeneratedContent>`.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>

```

--------------------------------

### Logging Feedback Attachments

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue

Explains how to log feedback attachments, including sentiment, issues, and desired output.

```APIDOC
## POST /websites/developer_apple_foundationmodels/logFeedbackAttachment

### Description
Logs and serializes data that includes session information, attached when reporting feedback to Apple. This function can include sentiment, issues, and the desired output.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/logFeedbackAttachment`

### Parameters
#### Request Body
- **sentiment** (LanguageModelFeedback.Sentiment) - Optional - The sentiment regarding the model's response.
- **issues** ([LanguageModelFeedback.Issue]) - Required - A list of issues encountered with the model's response.
- **desiredOutput** (Transcript.Entry) - Optional - The expected or desired output from the model.
```

--------------------------------

### SystemLanguageModel.Availability.available

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/available

Indicates that the system is ready for making requests. This is a static property of the SystemLanguageModel.Availability enum.

```APIDOC
## SystemLanguageModel.Availability.available

### Description
The system is ready for making requests.

### Method
N/A (Property)

### Endpoint
N/A

### Parameters
N/A

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A

### Platforms
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+

```swift
case available
```
```

--------------------------------

### LanguageModelSession Initializer

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal/init%28transcriptentries%3A%29

Initializes a LanguageModelSession with a collection of transcript entries.

```APIDOC
## Initializer: init(transcriptEntries:)

### Description
Initializes a new instance of `LanguageModelSession` with the provided transcript entries. This is useful for setting up a conversational context before starting a new generation.

### Method
`init`

### Endpoint
N/A (Initializes a Swift object)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
```swift
let entries: [Transcript.Entry] = [
    // ... populate with Transcript.Entry objects ...
]
let session = LanguageModelSession(transcriptEntries: entries)
```

### Response
#### Success Response (200)
N/A (This is an initializer, not an API endpoint)

#### Response Example
N/A
```

--------------------------------

### toolDefinitions

Source: https://developer.apple.com/documentation/foundationmodels/transcript/instructions/tooldefinitions

Provides a list of tools made available to the model for transcript processing.

```APIDOC
## GET /websites/developer_apple_foundationmodels/toolDefinitions

### Description
Retrieves a list of tools that are available to the foundation model for processing transcripts.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/toolDefinitions

### Parameters
This endpoint does not have any path, query, or request body parameters.

### Request Example
(No request body for GET)

### Response
#### Success Response (200)
- **toolDefinitions** ([Transcript.ToolDefinition]) - An array of tool definitions available to the model.

#### Response Example
```json
{
  "toolDefinitions": [
    {
      "id": "tool1",
      "name": "Example Tool",
      "description": "A sample tool for demonstration."
    }
  ]
}
```

## See Also
### Inspecting instructions
`var segments: [Transcript.Segment]`
The content of the instructions, in natural language.

```

--------------------------------

### Creating a session

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

Methods and types related to creating a new LanguageModelSession.

```APIDOC
### Creating a session

`convenience(model:tools:instructions:)`
Start a new session in blank slate state with instructions builder.

`class SystemLanguageModel`
An on-device large language model capable of text generation tasks.

`protocol Tool`
A tool that a model can call to gather information at runtime or perform side effects.

`struct Instructions`
Details you provide that define the model’s intended behavior on prompts.
```

--------------------------------

### Check Foundation Model Adapter Compatibility

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/iscompatible%28_%3A%29

This Swift method checks if an asset pack is an on-device foundation model adapter and is compatible with the system's base model version. It's useful for selecting appropriate adapters before downloading. Note that this check only validates metadata; runtime initialization might still fail.

```swift
static func isCompatible(_ assetPack: AssetPack) -> Bool
```

--------------------------------

### Initialize LanguageModelFeedback.Issue

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category

Initializes a new instance of an issue related to language model feedback. This initializer allows for specifying the category of the issue and an optional detailed explanation.

```swift
init(category: LanguageModelFeedback.Issue.Category, explanation: String?)
```

--------------------------------

### Accessing the Default Model

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

Provides static access to the default instance of the `SystemLanguageModel`, which represents the base version suitable for general-purpose text generation tasks.

```APIDOC
## Getting the default model

### `static let `default`: SystemLanguageModel`

This static property provides access to the base version of the `SystemLanguageModel`, intended for general-purpose text generation.
```

--------------------------------

### Build Conditional Prompt Component in Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder

Constructs a prompt using either the first or second provided `PromptRepresentable` component. This is used for handling conditional logic within prompt building.

```swift
static func buildEither(first value: some PromptRepresentable) -> Prompt
```

```swift
static func buildEither(second value: some PromptRepresentable) -> Prompt
```

--------------------------------

### Access Model Refusal Explanation (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal/explanation

Retrieves a detailed explanation for why a language model refused to generate a response. This property is asynchronous and may throw an error.

```swift
var explanation: LanguageModelSession.Response<String> { get async throws }
```

--------------------------------

### Prompt Inspection API

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/segments

Provides details and options for inspecting a prompt.

```APIDOC
## GET /websites/developer_apple_foundationmodels/prompt/inspect

### Description
Inspects a prompt to retrieve its identifier, response format, and generation options.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/prompt/inspect

### Parameters
#### Query Parameters
- **promptId** (string) - Required - The identifier of the prompt to inspect.

### Request Example
(No request body for GET)

### Response
#### Success Response (200)
- **id** (string) - The identifier of the prompt.
- **responseFormat** (Transcript.ResponseFormat) - An optional response format that describes the desired output structure.
- **options** (GenerationOptions) - Generation options associated with the prompt.

#### Response Example
{
  "id": "prompt123",
  "responseFormat": {
    "type": "json"
  },
  "options": {
    "temperature": 0.7,
    "maxTokens": 100
  }
}
```

--------------------------------

### Define Response Format Structure - Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/responseformat

Defines the structure for specifying a response format that an AI model must adhere to. This structure is foundational for controlling the model's output. It is available across multiple Apple platforms.

```swift
struct ResponseFormat
```

--------------------------------

### POST /websites/developer_apple_foundationmodels/streamResponse

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28to%3Aoptions%3A%29

Produces a response stream to a prompt using the Foundation Models API. This method is suitable for real-time interactions where a stream of tokens is desired.

```APIDOC
## POST /websites/developer_apple_foundationmodels/streamResponse

### Description
Produces a response stream to a prompt. This method is ideal for real-time responses where you want to process tokens as they are generated.

### Method
POST

### Endpoint
/websites/developer_apple_foundationmodels/streamResponse

### Parameters
#### Request Body
- **prompt** (Prompt) - Required - A specific prompt for the model to respond to.
- **options** (GenerationOptions) - Optional - GenerationOptions that control how tokens are sampled from the distribution the model produces.

### Request Example
```json
{
  "prompt": {
    "text": "Explain the concept of recursion in programming."
  },
  "options": {
    "temperature": 0.7,
    "maxTokens": 100
  }
}
```

### Response
#### Success Response (200)
- **responseStream** (LanguageModelSession.ResponseStream<String>) - A response stream that produces aggregated tokens.

#### Response Example
(This is an asynchronous stream, so a single JSON response example is not applicable. The response will be a stream of string tokens.)
```
// Example of receiving tokens from the stream
for await token in responseStream {
  print(token)
}
```

### Discussion
Important: If running in the background, use the non-streaming `respond(to:options:)` method to reduce the likelihood of encountering `LanguageModelSession.GenerationError.rateLimited(_:)` errors.

### See Also
- `func streamResponse(to:generating:includeSchemaInPrompt:options:)`
- `func streamResponse(to:schema:includeSchemaInPrompt:options:)`
- `func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>`
- `func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>`
- `func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>`
- `struct ResponseStream`
- `struct GeneratedContent`
- `protocol ConvertibleFromGeneratedContent`
- `protocol ConvertibleToGeneratedContent`
```

--------------------------------

### Initialize LanguageModelSession with Transcript Entries

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal/init%28transcriptentries%3A%29

Initializes a `LanguageModelSession` with a provided array of `Transcript.Entry` objects. This initializer is crucial for setting up a session based on a pre-existing conversation history or data structure. It is available across multiple Apple platforms.

```swift
init(transcriptEntries: [Transcript.Entry])
```

--------------------------------

### Create GenerationID using init()

Source: https://developer.apple.com/documentation/foundationmodels/generationid/init%28%29

The init() function creates a new, unique GenerationID. This initializer is a fundamental part of the Foundation Models framework for generating identifiers. It has no explicit parameters or return values shown in this basic form.

```swift
init()
```

--------------------------------

### Define compatibleAdapterNotFound Error Case

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror/compatibleadapternotfound%28_%3A%29

This Swift code snippet defines the `compatibleAdapterNotFound` error case within the `SystemLanguageModel.Adapter.AssetError` enum. It includes a parameter of type `SystemLanguageModel.Adapter.AssetError.Context` to provide details about the error's occurrence. This error is raised when no compatible adapters are found for the current system base model.

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```

--------------------------------

### Inspect a Tool Definition - Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition

Provides access to the name and description of a ToolDefinition. The description explains how and when to use the tool. This structure is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS from version 26.0 onwards.

```swift
struct ToolDefinition
var description: String
var name: String
```

--------------------------------

### Enable Custom Adapters for Foundation Models

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

This entitlement allows your application to load and use custom adapters for the Foundation Models framework. It is a boolean value that must be set to `true` to enable this functionality.

```xml
<key>com.apple.developer.foundation-model-adapter</key>
<true/>
```

--------------------------------

### Create GeneratedContent with Custom ID - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28_%3Aid%3A%29

Initializes a `GeneratedContent` instance with a single value and a custom `GenerationID`. This initializer requires the `value` parameter to be convertible to `GeneratedContent` and accepts a `GenerationID` for identification. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS version 26.0 and later.

```swift
init(
    _ value: some ConvertibleToGeneratedContent,
    id: GenerationID
)
```

--------------------------------

### Track Adapter Download Status

Source: https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

Asynchronously tracks the download status of a Foundation Model adapter. It retrieves the asset pack ID, monitors download progress, and returns true if the download completes successfully, or false if it fails. This function is crucial for ensuring the adapter is ready before use.

```swift
func checkAdapterDownload(name: String) async -> Bool {
    // Get the ID of the compatible adapter.
    let assetpackIDList = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(
        name: name
    )


    if let assetPackID = assetpackIDList.first {
        // Get the download status asynchronous sequence.
        let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)


        // Use the current status to update any loading UI.
        for await status in statusUpdates {
            switch status {
            case .began(let assetPack):
                // The download started.
            case .paused(let assetPack):
                // The download is in a paused state.
            case .downloading(let assetPack, let progress):
                // The download in progress.
            case .finished(let assetPack):
                // The download is complete and the adapter is ready to use.
                return true
            case .failed(let assetPack, let error):
                // The download failed.
                return false
            @unknown default:
                // The download encountered an unknown status.
                fatalError()
            }
        }
    }
    return false
}

```

--------------------------------

### includesSchemaInInstructions Property

Source: https://developer.apple.com/documentation/foundationmodels/tool/includesschemaininstructions

Controls whether the model's name, description, and parameters schema are injected into the instructions of sessions that leverage this tool. The default value is true.

```APIDOC
## includesSchemaInInstructions Property

### Description
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

### Property
`includesSchemaInInstructions: Bool`

### Availability
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+

### Default Implementation
The default implementation is `true`.

### Discussion
This should only be `false` if the model has been trained to have innate knowledge of this tool. For zero-shot prompting, it should always be `true`.

### See Also
- `description: String`
- `name: String`
- `parameters: GenerationSchema`
```

--------------------------------

### Swift: Call Tool with Arguments

Source: https://developer.apple.com/documentation/foundationmodels/tool/call%28arguments%3A%29

The `call(arguments:)` method is used by a language model to invoke a tool, requiring specific argument and output types. Errors thrown within this method are wrapped in `LanguageModelSession.ToolCallError`.

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```

--------------------------------

### Instance Property: name

Source: https://developer.apple.com/documentation/foundationmodels/tool/name

The 'name' property represents a unique identifier for a tool. This name should be descriptive and follow a convention like 'get_weather' or 'search_contacts' to clearly indicate the tool's function.

```APIDOC
## Instance Property: name

### Description
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.

### Platform Availability
iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+

### Usage
```swift
var name: String { get }
```

**Required**. Default implementation provided.
```

--------------------------------

### LanguageModelSession Initializer

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init%28model%3Atools%3Atranscript%3A%29

Initializes a LanguageModelSession by rehydrating from a transcript, allowing you to resume a previous conversation or interaction.

```APIDOC
## `init(model:tools:transcript:)`

### Description
Start a session by rehydrating from a transcript.

### Method
`convenience init`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
Initializes a `LanguageModelSession` object.

#### Response Example
None

### Discussion
#### Parameters
*   **model** (`SystemLanguageModel`)
    *   The language model to use for this session. Defaults to `.default`.
*   **tools** (`[any Tool]`)
    *   Tools to make available to the model for this session. Defaults to an empty array.
*   **transcript** (`Transcript`)
    *   A transcript to resume from.
```

--------------------------------

### InstructionsBuilder Struct Definition

Source: https://developer.apple.com/documentation/foundationmodels/instructionsbuilder

Defines the core InstructionsBuilder result builder struct, which is used to construct `Instructions` objects programmatically in Swift. This is the foundational element for building instruction sequences.

```swift
@resultBuilder
struct InstructionsBuilder
```

--------------------------------

### String Validation with anyOf(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/anyof%28_%3A%29

This method enforces that a string value must be one of the strings provided in the input array. It returns a GenerationGuide specialized for strings, ensuring type safety. This is useful for validating user input or configuration settings.

```swift
static func anyOf(_ values: [String]) -> GenerationGuide<String>
```

--------------------------------

### Initialize LanguageModelSession with Transcript (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init%28model%3Atools%3Atranscript%3A%29

Initializes a `LanguageModelSession` by rehydrating from a provided transcript. This method allows resuming a previous conversation or interaction with the language model. It accepts an optional `SystemLanguageModel`, an array of `Tool` objects, and a required `Transcript` object.

```swift
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    transcript: Transcript
)
```

--------------------------------

### Initialize SystemLanguageModel with Permissive Guardrails (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

Initializes a SystemLanguageModel with permissive content transformations to allow reasoning about sensitive source material. This mode is suitable for string generation tasks where default guardrail violations might occur. Note that on-device safety layers still exist, and refusals may still be generated.

```swift
let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
```

--------------------------------

### Create Prompt Builder with Array - Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildarray%28_%3A%29

The `buildArray(_:)` static method constructs a `Prompt` builder from an array of elements conforming to `PromptRepresentable`. This function is essential for assembling complex prompts by grouping multiple prompt components into a single structure. It requires an array of prompts as input and returns a unified `Prompt` object.

```swift
static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt
```

--------------------------------

### Create GeneratedContent with Duplicate Key Resolution

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/init%28properties%3Aid%3Auniquingkeyswith%3A%29

This initializer creates new `GeneratedContent` from a sequence of key-value pairs. It uses a combining closure to resolve any duplicate keys encountered during content creation. The order of properties is crucial for `Generable` types, matching their schema order. The closure can choose between values, combine them, or throw an error.

```swift
init<S>(
    properties: S,
    id: GenerationID? = nil,
    uniquingKeysWith combine: (GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent
) rethrows where S : Sequence, S.Element == (String, any ConvertibleToGeneratedContent)
```

```swift
let content = GeneratedContent(
  properties: [("name", "John"), ("name", "Jane"), ("married", true)],
  uniquingKeysWith: { (first, _) in first }
)
// GeneratedContent(["name": "John", "married": true])
```

--------------------------------

### Create Array Schema with min/max elements - Swift

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init%28arrayof%3Aminimumelements%3Amaximumelements%3A%29

Initializes an array schema for dynamic generation. It takes a schema for array items and optional minimum and maximum element counts. This is useful for defining structured data validation for arrays.

```swift
init(
    arrayOf itemSchema: DynamicGenerationSchema,
    minimumElements: Int? = nil,
    maximumElements: Int? = nil
)
```

--------------------------------

### Preloading the model

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

Method to preload the model's resources into memory for reduced latency.

```APIDOC
### Preloading the model

`func prewarm(promptPrefix: Prompt?)`
Loads the resources required for this session into memory, and optionally caches a prefix of your prompt to reduce request latency.
```

--------------------------------

### Swift: Generating a Response with String Content

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response

Asynchronously generates a string response to a given prompt using specified options. This function is part of the `LanguageModelSession` and returns a `LanguageModelSession.Response<String>`.

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>

```

--------------------------------

### Accessing the Default SystemLanguageModel

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/default

This code snippet shows how to access the default `SystemLanguageModel`. This is the base version of the model, useful for general-purpose tasks. It requires iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, or visionOS 26.0+.

```swift
static let `default`: SystemLanguageModel
```

--------------------------------

### Streaming Response Functions for ConvertibleToGeneratedContent

Source: https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent

Demonstrates various overloaded functions for streaming responses from a prompt, with options for schema inclusion and specific content types. These functions return a ResponseStream.

```swift
func streamResponse(to:options:)
func streamResponse(to:generating:includeSchemaInPrompt:options:)
func streamResponse(to:schema:includeSchemaInPrompt:options:)
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```

--------------------------------

### Log Language Model Feedback with Sentiment and Issues (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback

This Swift code snippet demonstrates how to log feedback for a language model session. It shows the creation of a LanguageModelSession, obtaining a response, and then logging feedback with specified sentiment, issues, and desired output. This is useful for developers who need to report issues or provide feedback on model performance.

```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "What is the capital of France?")


// Create feedback for a problematic response.
let feedbackData = session.logFeedbackAttachment(
    sentiment: LanguageModelFeedback.Sentiment.negative,
    issues: [
        LanguageModelFeedback.Issue(
            category: .incorrect,
            explanation: "The model provided outdated information"
        )
    ],
    desiredOutput: Transcript.Entry.response(...)
)

```

--------------------------------

### Instance Property: content

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment/content

Retrieves or sets the content of a structured segment. This property is available from iOS 26.0 onwards.

```APIDOC
## Instance Property: content

### Description
The content of the segment.

### Availability
iOS 26.0+ 
iPadOS 26.0+ 
Mac Catalyst 26.0+ 
macOS 26.0+ 
visionOS 26.0+

### Swift
```swift
var content: GeneratedContent { get set }
```

### See Also

#### Inspecting a structured segment
`var source: String`
A source that be used to understand which type content represents.
```

--------------------------------

### Protocol Definition for Tool

Source: https://developer.apple.com/documentation/foundationmodels/tool

Defines the `Tool` protocol, a generic type with `Arguments` and `Output` associated types. It requires conformance to `Sendable` for concurrent execution.

```swift
protocol Tool<Arguments, Output> : Sendable
```

--------------------------------

### Transcript.TextSegment API

Source: https://developer.apple.com/documentation/foundationmodels/transcript/textsegment

Documentation for the Transcript.TextSegment structure, including its initialization and properties.

```APIDOC
## Transcript.TextSegment

A segment containing text.

### Description
Represents a segment of text within a transcript.

### Topics

#### Creating a text segment
`init(id: String, content: String)`
Initializes a new TextSegment with a unique identifier and the text content.

#### Inspecting a text segment
`var content: String`
Gets the text content of the segment.

### Conforms To
* `Copyable`
* `CustomStringConvertible`
* `Equatable`
* `Identifiable`
* `Sendable`
* `SendableMetatype`

### See Also
* `struct Instructions`
* `struct Prompt`
* `struct Response`
* `struct ResponseFormat`
* `struct StructuredSegment`
* `struct ToolCall`
* `struct ToolCalls`
* `struct ToolDefinition`
* `struct ToolOutput`
```

--------------------------------

### LanguageModelSession.ResponseStream API

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream

Provides methods for interacting with streaming responses from foundation models, allowing for collection of the complete response or retrieval of partial snapshots.

```APIDOC
## LanguageModelSession.ResponseStream

An async sequence of snapshots of partially generated content.

### Description

Represents a stream of responses from a foundation model, allowing you to process content as it becomes available.

### Structure

```swift
struct ResponseStream<Content> where Content : Generable
```

### Methods

#### collect()

```swift
func collect() async throws -> sending LanguageModelSession.Response<Content>
```

**Description**: Retrieves the complete response from the stream after it has finished generating.

**Returns**: The final `LanguageModelSession.Response<Content>` object.

### Topics

#### Snapshot

```swift
struct Snapshot
```

**Description**: Represents a single, partially generated piece of content from the response stream.

### See Also

#### Streaming a response

- `func streamResponse(to:options:)`
- `func streamResponse(to:generating:includeSchemaInPrompt:options:)`
- `func streamResponse(to:schema:includeSchemaInPrompt:options:)`
- `func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>`
- `func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>`
- `func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>`

### Conforms To

- `AsyncSequence`
- `Copyable`
```

--------------------------------

### Access instructionsRepresentation - Swift

Source: https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation-57k7v

This code snippet shows how to access the `instructionsRepresentation` property, which returns an object conforming to the `Instructions` protocol. This property is read-only and is available on various Apple platforms from iOS 26.0 onwards.

```swift
var instructionsRepresentation: Instructions { get }
```

--------------------------------

### Handle Tool Call Errors (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling

Shows how to handle `LanguageModelSession.ToolCallError` when a tool encounters an error during execution. This allows for accessing the specific tool that failed and its underlying error, facilitating custom error handling logic.

```swift
do {
    let answer = try await session.respond("Find a recipe for tomato soup.")
} catch let error as LanguageModelSession.ToolCallError {
        
    // Access the name of the tool, like BreadDatabaseTool.
    print(error.tool.name) 
        
    // Access an underlying error that your tool throws and check if the tool 
    // encounters a specific condition.
    if case .databaseIsEmpty = error.underlyingError as? SearchBreadDatabaseToolError {
        // Display an error in the UI.
    }


} catch {
    print("Some other error: (error)")
}

```

--------------------------------

### Swift: Generating a Generable Object Response

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response

Asynchronously generates a response of a specific generable type (`Content`) to a prompt. It allows control over including the schema in the prompt and uses provided generation options. Returns a `LanguageModelSession.Response<Content>`.

```swift
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>

```

--------------------------------

### Generate and Verify Character Dialog - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Handles generating a response from a LanguageModelSession and verifying its content against a safety check. If the dialog is deemed inappropriate, it resets the conversation and uses a predefined error response.

```swift
let response = try await session.respond(
    to: userInput
)
let dialog = response.content


// Verify whether the input contains any blocked words or phrases.
if textIsOK(dialog) {
    nextUtterance = dialog
    isGenerating = false
} else {
    nextUtterance = character.errorResponse
    isGenerating = false
    resetSession(character, startWith: character.resumeConversationLine)
}

```

--------------------------------

### logFeedbackAttachment Instance Method

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredresponsecontent%3A%29

Logs and serializes data that includes session information that you attach when reporting feedback to Apple.

```APIDOC
## logFeedbackAttachment(sentiment:issues:desiredResponseContent:)

### Description
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.

### Method
`final func`

### Endpoint
Instance Method

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
- **sentiment** (LanguageModelFeedback.Sentiment?) - Optional - The sentiment of the feedback.
- **issues** ([LanguageModelFeedback.Issue]) - Optional - A list of issues related to the feedback.
- **desiredResponseContent** ((any ConvertibleToGeneratedContent)?) - Optional - The desired content for the response.

### Request Example
```json
{
  "sentiment": "positive",
  "issues": ["incorrect_information"],
  "desiredResponseContent": "some_content"
}
```

### Response
#### Success Response (200)
- **Data** (Data) - The serialized feedback data.

#### Response Example
```json
{
  "data": "serialized_feedback_data"
}
```
```

--------------------------------

### Define LanguageModelSession.ResponseStream.Snapshot Structure

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot

Defines the structure for a snapshot of partially generated content from a language model response stream. This structure provides access to both processed and raw content, allowing for flexible handling of real-time model outputs.

```swift
struct Snapshot
```

--------------------------------

### Create Tool Call Error - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror/init%28tool%3Aunderlyingerror%3A%29

Initializes a `LanguageModelSession.ToolCallError` with the tool that caused the error and the underlying error. This is used to represent errors that occur during tool execution within a language model session.

```swift
init(
    tool: any Tool,
    underlyingError: any Error
)
```

--------------------------------

### UnavailableReason Cases for SystemLanguageModel

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason

This snippet lists the specific cases for the UnavailableReason enumeration. These cases detail the exact reasons a language model might be unavailable, such as Apple Intelligence not being enabled or the device not being eligible.

```swift
case appleIntelligenceNotEnabled
case deviceNotEligible
case modelNotReady
```

--------------------------------

### GenerationSchema.SchemaError.Context Structure

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/context

Provides details about the GenerationSchema.SchemaError.Context structure, including its initialization and properties.

```APIDOC
## GenerationSchema.SchemaError.Context

### Description
The context in which the error occurred.

### Structure
```swift
struct Context
```

### Topics

#### Creating a schema error context
`init(debugDescription: String)`
Initializes a new context with a debug description.

#### Getting the debug description
`let debugDescription: String`
A string representation of the debug description.

### Relationships

#### Conforms To
- `Sendable`
- `SendableMetatype`

### See Also

#### Getting schema errors
- `case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)`: An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.
- `case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)`: An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.
- `case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)`: An error that represents an attempt to construct an anyOf schema with an empty array of type choices.
- `case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)`: An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.
```

--------------------------------

### Swift: Simplified Response Generation (Deprecated or Overloaded)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response

These are simplified function signatures for generating responses, potentially overloaded or deprecated versions of the more detailed `respond` functions. They take a prompt and options to produce a response.

```swift
func respond(to:options:)
func respond(to:generating:includeSchemaInPrompt:options:)
func respond(to:schema:includeSchemaInPrompt:options:)

```

--------------------------------

### Logging Feedback

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

Functions for logging feedback related to language model interactions, including sentiment, issues, and desired responses.

```APIDOC
## POST /websites/developer_apple_foundationmodels/feedback/log

### Description
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/feedback/log`

### Parameters
#### Request Body
- **sentiment** (LanguageModelFeedback.Sentiment) - Optional - The sentiment of the feedback.
- **issues** (Array of LanguageModelFeedback.Issue) - Required - A list of issues identified in the response.
- **desiredOutput** (Transcript.Entry) - Optional - The desired output as a transcript entry.

### Request Example
```json
{
  "sentiment": "positive",
  "issues": ["typo"],
  "desiredOutput": { ... }
}
```

### Response
#### Success Response (200)
- **Data** (Data) - Serialized feedback data.

#### Response Example
```json
{
  "data": "serialized_feedback_data"
}
```

## POST /websites/developer_apple_foundationmodels/feedback/log/response

### Description
Logs feedback with a desired response content.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/feedback/log/response`

### Parameters
#### Request Body
- **sentiment** (LanguageModelFeedback.Sentiment) - Optional - The sentiment of the feedback.
- **issues** (Array of LanguageModelFeedback.Issue) - Required - A list of issues identified in the response.
- **desiredResponseContent** (ConvertibleToGeneratedContent) - Optional - The desired response content.

### Request Example
```json
{
  "sentiment": "negative",
  "issues": ["inaccurate"],
  "desiredResponseContent": { ... }
}
```

### Response
#### Success Response (200)
- **Data** (Data) - Serialized feedback data.

#### Response Example
```json
{
  "data": "serialized_feedback_data"
}
```

## POST /websites/developer_apple_foundationmodels/feedback/log/text

### Description
Logs feedback with a desired response text.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/feedback/log/text`

### Parameters
#### Request Body
- **sentiment** (LanguageModelFeedback.Sentiment) - Optional - The sentiment of the feedback.
- **issues** (Array of LanguageModelFeedback.Issue) - Required - A list of issues identified in the response.
- **desiredResponseText** (String) - Optional - The desired response text.

### Request Example
```json
{
  "sentiment": "neutral",
  "issues": ["formatting"],
  "desiredResponseText": "Corrected response text"
}
```

### Response
#### Success Response (200)
- **Data** (Data) - Serialized feedback data.

#### Response Example
```json
{
  "data": "serialized_feedback_data"
}
```
```

--------------------------------

### Declare Description Property - Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition/description

This code snippet demonstrates the declaration of the 'description' instance property in Swift. This property is of type String and is intended to describe how and when a tool should be used.

```swift
var description: String
```

--------------------------------

### Declare SystemLanguageModel.Availability.unavailable(_:)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailable%28_%3A%29

This Swift code snippet declares the `unavailable(_:)` case for `SystemLanguageModel.Availability`. It signifies that the system is not currently prepared to handle requests and requires a reason for this unavailability.

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```

--------------------------------

### Stream Itinerary Plan Generation

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

Generates a multi-day itinerary for a given landmark, streaming partial responses to display content incrementally. It uses a greedy sampling mode for consistent output. The ItineraryPlanner class handles this process.

```swift
private(set) var itinerary: Itinerary.PartiallyGenerated?


func suggestItinerary(dayCount: Int) async throws {
    let stream = session.streamResponse(
        generating: Itinerary.self,
        includeSchemaInPrompt: false,
        options: GenerationOptions(sampling: .greedy)
    ) {
        "Generate a \(dayCount)-day itinerary to \(landmark.name)."


        "Give it a fun title and description."


        "Here is an example, but don't copy it:"
        Itinerary.exampleTripToJapan
    }


    for try await partialResponse in stream {
        itinerary = partialResponse.content
    }
}
```

--------------------------------

### Define Tool Output in Transcript Entry

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/tooloutput%28_%3A%29

This code snippet demonstrates how to define the `toolOutput` case for a `Transcript.Entry`. This case is used to represent an tool output provided back to the model. It requires the `Transcript.ToolOutput` type to be defined. This is a Swift enum case definition.

```swift
case toolOutput(Transcript.ToolOutput)
```

--------------------------------

### Representing an Array of GeneratedContent

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/array%28_%3A%29

This code snippet demonstrates how to represent an array of GeneratedContent elements using the `array` case. It takes an array of `GeneratedContent` instances as its parameter.

```swift
case array([GeneratedContent])
```

--------------------------------

### Generate a Response with LanguageModelSession

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

These functions generate a response to a prompt using the LanguageModelSession. They support returning plain text, generable objects, or structured content based on a schema. Options can be provided to control the generation process.

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
func respond(to:options:)
func respond(to:generating:includeSchemaInPrompt:options:)
func respond(to:schema:includeSchemaInPrompt:options:)
```

--------------------------------

### Dynamic Generation Schema Creation

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/property

Methods for creating various types of dynamic generation schemas, including array, any-of, object, reference, and generable type schemas.

```APIDOC
## Creating a dynamic schema

### Description
Methods to construct different types of dynamic generation schemas.

### Initializers

1.  **Array Schema**
    `init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`
    Creates an array schema with optional minimum and maximum element constraints.

2.  **Any-of Schema**
    `init(name: String?, description: String?, anyOf: [DynamicGenerationSchema])`
    Creates an any-of schema, allowing the schema to match any of the provided schemas.

3.  **Object Schema**
    `init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`
    Creates an object schema composed of a list of properties.

4.  **Reference Schema**
    `init(referenceTo: String)`
    Creates a schema that references another schema by its string identifier.

5.  **Generable Type Schema**
    `init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])`
    Creates a schema from a generable type and associated generation guides.

### Request Example
```json
{
  "example": "Schema creation example"
}
```

### Response
#### Success Response (200)
None

#### Response Example
```json
{
  "example": "Schema creation response example"
}
```
```

--------------------------------

### Declaring SystemLanguageModel Class

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

This is the basic declaration of the SystemLanguageModel class, indicating its availability on various Apple platforms. It serves as the entry point for interacting with the on-device language model.

```swift
final class SystemLanguageModel
```

--------------------------------

### Swift Initializer for 'any-of' Dynamic Generation Schema

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init%28name%3Adescription%3Aanyof%3A%29

This Swift initializer creates an 'any-of' schema, which represents a union of other schemas. It takes a name, an optional description, and an array of `DynamicGenerationSchema` objects as its choices. This schema is useful for defining validation rules where an input must conform to at least one of the provided schemas.

```swift
init(
    name: String,
    description: String? = nil,
    anyOf choices: [DynamicGenerationSchema]
)
```

--------------------------------

### Generate Locale Instructions (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models

This Swift function generates instructions for setting the locale for Foundation Models. It checks if the current locale is U.S. English and returns an empty string if it is, otherwise, it returns a formatted string specifying the locale. This helps in improving response quality for multilingual situations.

```swift
func localeInstructions(for locale: Locale = Locale.current) -> String {
    if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
        // Skip the locale phrase for U.S. English.
        return "" 
    } else {
        // Specify the person's locale with the exact phrase format.
        return "The person's locale is \(locale.identifier)."
    }
}

```

--------------------------------

### SystemLanguageModel Guardrails Default

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails/default

Provides information about the default guardrails for the SystemLanguageModel. This mode ensures that unsafe content in prompts and responses will be blocked with a `LanguageModelSession.GenerationError.guardrailViolation` error.

```APIDOC
## SystemLanguageModel Guardrails Default

### Description
Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a `LanguageModelSession.GenerationError.guardrailViolation` error.

### Method
N/A (static property)

### Endpoint
N/A (static property)

### Parameters
N/A

### Request Example
N/A

### Response
#### Success Response (N/A)
- **`default`** (SystemLanguageModel.Guardrails) - The default guardrails object.

#### Response Example
N/A

## See Also
### Getting the guardrail types
`static let permissiveContentTransformations: SystemLanguageModel.Guardrails`
Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.
```

--------------------------------

### anyOf(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/anyof%28_%3A%29

The `anyOf(_:)` static method in Foundation Models allows you to create a validation rule that checks if a given string is present within a provided array of acceptable string values.

```APIDOC
## `anyOf(_:)`

### Description
Enforces that the string be one of the provided values.

### Method
`static func anyOf(_ values: [String]) -> GenerationGuide<String>`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```json
{
  "example": "Example string input"
}
```

### Response
#### Success Response (200)
This method returns a `GenerationGuide<String>` object configured with the specified validation rule.

#### Response Example
```json
{
  "example": "GenerationGuide<String> object"
}
```

## See Also
### Getting the constant
`static func constant(String) -> GenerationGuide<String>`
Enforces that the string be precisely the given value.
```

--------------------------------

### Swift: Initialize GeneratedContent from JSON String

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent

Creates a GeneratedContent instance from a JSON string. This initializer is part of the GeneratedContent type and is available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

```swift
init(json: String) throws
```

--------------------------------

### Build Prompt from Array in Swift

Source: https://developer.apple.com/documentation/foundationmodels/promptbuilder

Constructs a prompt from an array of `PromptRepresentable` types. This method is part of the `PromptBuilder` result builder.

```swift
static func buildArray<C>(_ components: C) -> Prompt where C: Collection, C.Element: PromptRepresentable
```

--------------------------------

### Check model availability using SystemLanguageModel

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

This Swift code snippet demonstrates how to check the availability of the on-device language model using `SystemLanguageModel.default`. It handles different availability states, including `.available`, `.unavailable(.appleIntelligenceNotEnabled)`, and `.unavailable(.modelNotReady)`, providing appropriate user messages for each.

```swift
let landmark: Landmark
private let model = SystemLanguageModel.default

var body: some View {
    switch model.availability {
    case .available:
        LandmarkTripView(landmark: landmark)
    case .unavailable(.appleIntelligenceNotEnabled):
        MessageView(
            landmark: self.landmark,
            message: """
                     Trip Planner is unavailable because \ 
                     Apple Intelligence hasn't been turned on.
                     """
        )
    case .unavailable(.modelNotReady):
        MessageView(
            landmark: self.landmark,
            message: "Trip Planner isn't ready yet. Try again later."
        )
    }
}
```

--------------------------------

### Swift - Foundation Models Sampling Property

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/sampling

Defines a sampling strategy for controlling how a foundation model selects tokens during response generation. Leaving this property as nil allows the system to choose a default strategy. The sampling strategy influences the predictability and naturalness of the generated response.

```swift
var sampling: GenerationOptions.SamplingMode?
```

--------------------------------

### Creating Transcript Entry from String in Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredoutput%3A%29

Illustrates how to create a `Transcript.Entry` from a string, which is useful when specifying the `desiredOutput` parameter for the `logFeedbackAttachment` method. It converts a plain text response into a structured `Transcript.Entry`.

```swift
let text = Transcript.TextSegment(content: "The capital of France is Paris.")
let segment = Transcript.Segment.text(text)
let response = Transcript.Response(segments: [segment])
let entry = Transcript.Entry.response(response)
```

--------------------------------

### Check Locale Support for Foundation Model

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportslocale%28_%3A%29

This endpoint allows you to check if a given locale is supported by the Foundation Model. It considers language fallbacks for a more accurate assessment.

```APIDOC
## GET /websites/developer_apple_foundationmodels/supportsLocale

### Description
Returns a Boolean indicating whether the given locale is supported by the model.

### Method
GET

### Endpoint
`/websites/developer_apple_foundationmodels/supportsLocale`

### Parameters
#### Query Parameters
- **locale** (Locale) - Optional - The locale to check for support. Defaults to the current locale.

### Request Example
```json
{
  "locale": "en-US"
}
```

### Response
#### Success Response (200)
- **supported** (Boolean) - True if the locale is supported, false otherwise.

#### Response Example
```json
{
  "supported": true
}
```

### Discussion
Use this method over `supportedLanguages` to check whether the given locale qualifies a user for using this model, as this method will take into consideration language fallbacks.
```

--------------------------------

### SystemLanguageModel Default

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/default

Provides access to the default SystemLanguageModel, a generic model suitable for a wide range of applications.

```APIDOC
## SystemLanguageModel `default`

### Description
The base version of the model. This is a generic model that is useful for a wide variety of applications, but is not specialized to any particular use case.

### Availability
iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+ | macOS 26.0+ | visionOS 26.0+

### Type
`static let default: SystemLanguageModel`

### Usage
This model can be used for generating content and performing various tasks. It is mentioned in the context of 'Generating content and performing tasks with Foundation Models'.
```

--------------------------------

### Transcript.Response API

Source: https://developer.apple.com/documentation/foundationmodels/transcript/response

This section details the Transcript.Response structure, which represents a response from a model. It includes information on how to initialize a response and access its properties like segments and asset identifiers.

```APIDOC
## Transcript.Response
A response from the model.

### Description
Represents a response generated by a model, containing segments and associated asset identifiers.

### Initializers
#### `init(id: String, assetIDs: [String], segments: [Transcript.Segment])`
Initializes a new `Response` instance.

### Properties
#### `segments`
- **Type**: `[Transcript.Segment]`
- **Description**: Ordered prompt segments included in the response.

#### `assetIDs`
- **Type**: `[String]`
- **Description**: Version-aware identifiers for all assets used to generate this response.
```

--------------------------------

### Swift `instructionsRepresentation` Property

Source: https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation

This snippet shows the declaration of the `instructionsRepresentation` instance property in Swift. It is marked with the `@InstructionsBuilder` attribute and returns an `Instructions` type. This property is required and has a default implementation provided by the `InstructionsRepresentable` protocol.

```swift
@InstructionsBuilder
var instructionsRepresentation: Instructions { get }
```

--------------------------------

### SystemLanguageModel.Adapter.AssetError Enumeration

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror

Details the AssetError enumeration within the SystemLanguageModel.Adapter module, outlining the different types of asset-related errors that can occur.

```APIDOC
## SystemLanguageModel.Adapter.AssetError

### Description
An enumeration representing errors that can occur during asset loading or validation for language models.

### Enumeration Cases

#### `compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)`
Description: An error that occurs if no compatible adapters are found for the current system's base model.

#### `invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)`
Description: An error that occurs if the provided adapter name is invalid.

#### `invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)`
Description: An error that occurs if the provided asset files are invalid.

### Structs

#### `Context`
Description: The context in which the asset error occurred.

### Properties

#### `errorDescription` (String?)
Description: A string representation of the error description.

### Conformance
This enumeration conforms to the `Error`, `LocalizedError`, and `Sendable` protocols.
```

--------------------------------

### Generate Feedback Attachment (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredresponsetext%3A%29

Generates feedback logs with optional issues and desired output or content. This overload is primarily used for generating feedback data that includes session details.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
```

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredResponseContent: (any ConvertibleToGeneratedContent)?) -> Data
```

--------------------------------

### Swift: Define Transcript.ToolOutput Structure

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooloutput

Defines the structure for tool output, including its unique identifier, the name of the tool that generated it, and the segments of the output. Available on iOS 26.0+ and later.

```swift
struct ToolOutput
{
```

--------------------------------

### Access Transcript.ToolCall Arguments

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall

Retrieves the arguments that should be passed to the invoked tool. These arguments are of type `GeneratedContent` and specify the data required for the tool's execution.

```swift
var arguments: GeneratedContent
```

--------------------------------

### Swift: Accessing Response Content

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response

Provides access to the generated content of a response. `content` returns the typed response, while `rawContent` provides the raw generated content. These are properties of the LanguageModelSession.Response structure.

```swift
let content: Content
let rawContent: GeneratedContent

```

--------------------------------

### Swift: Related Unavailable Reasons for SystemLanguageModel

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/modelnotready

This Swift code snippet demonstrates other possible unavailability reasons for Apple Intelligence models. These include `appleIntelligenceNotEnabled` when the feature is off on the system, and `deviceNotEligible` if the device hardware does not support the feature.

```swift
case appleIntelligenceNotEnabled
case deviceNotEligible
```

--------------------------------

### Tool Definition - Description Property

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition/description

This section details the 'description' property within a tool definition for Foundation Models.

```APIDOC
## GET /websites/developer_apple_foundationmodels/description

### Description
Retrieves the description of a tool definition, explaining how and when to use the tool.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/description

### Parameters
This endpoint does not have path or query parameters.

### Request Body
This endpoint does not have a request body.

### Request Example
```
(No request body for this GET endpoint)
```

### Response
#### Success Response (200)
- **description** (String) - A description of how and when to use the tool.

#### Response Example
```json
{
  "description": "A detailed explanation of the tool's purpose and usage guidelines."
}
```

## See Also
### Inspecting a tool definition
* `var name: String` - The tool’s name.

```

--------------------------------

### Inspecting session properties

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

Properties to inspect the current state and history of the session.

```APIDOC
### Inspecting session properties

`var isResponding: Bool`
A Boolean value that indicates a response is being generated.

`var transcript: Transcript`
A full history of interactions, including user inputs and model responses.
```

--------------------------------

### Generation Options API

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/options

Provides access to generation options associated with a prompt. These options control how the model generates responses.

```APIDOC
## GET /websites/developer_apple_foundationmodels/options

### Description
Retrieves the generation options associated with a prompt. These options allow customization of the model's output.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/options

### Parameters
#### Query Parameters
None

### Request Example
(No request body for GET request)

### Response
#### Success Response (200)
- **options** (GenerationOptions) - An object containing the generation configuration. This object includes settings that influence the output of the foundation model.

#### Response Example
```json
{
  "options": {
    "temperature": 0.7,
    "maxTokens": 100
  }
}
```
```

--------------------------------

### LanguageModelSession.GenerationError.assetsUnavailable(_:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/assetsunavailable%28_%3A%29

This error indicates that the assets required for the session are unavailable. This can occur if model availability was not checked initially, if model assets were deleted, or if the user disables AppleIntelligence during app execution. Recovery might be possible by retrying later after the device has freed up space for redownloading.

```APIDOC
## LanguageModelSession.GenerationError.assetsUnavailable(_:)

### Description
An error that indicates the assets required for the session are unavailable. This may happen if you forget to check model availability to begin with, or if the model assets are deleted. This can happen if the user disables AppleIntelligence while your app is running.

You may be able to recover from this error by retrying later after the device has freed up enough space to redownload model assets.

### Method
N/A (This is an enum case)

### Endpoint
N/A (This is an enum case)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A
```

--------------------------------

### Retrieving Supported Languages

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

Returns a set of `Locale.Language` objects representing all the languages that the `SystemLanguageModel` supports for text generation and processing.

```APIDOC
## Retrieving the supported languages

### `var supportedLanguages: Set<Locale.Language>`

This property returns a set containing `Locale.Language` objects, indicating all the languages the model is capable of processing and generating.
```

--------------------------------

### Implement Deny List for Input and Output Verification (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

Applies a deny list to filter out unwanted terms from both user input and model output. This involves creating a verification function to check content against a predefined list of blocked terms.

```swift
let session = LanguageModelSession()
let userInput = // The input a person enters in the app.
let prompt = "Generate a wholesome story about: \(userInput)"


// A function you create that evaluates whether the input 
// contains anything in your deny list.
if verifyText(prompt) { 
    let response = try await session.respond(to: prompt)
    
    // Compare the output to evaluate whether it contains anything in your deny list.
    if verifyText(response.content) {
        return response 
    } else {
        // Handle the unsafe output.
    }
} else {
    // Handle the unsafe input.
}

```

--------------------------------

### pattern(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/pattern%28_%3A%29

This method enforces that a string follows a specified regular expression pattern. It is available for String values and returns a GenerationGuide configured with the regex pattern.

```APIDOC
## static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String>

### Description
Enforces that the string follows the pattern defined by the provided regular expression.

### Method
Static

### Endpoint
N/A (This is a library method, not a web API endpoint)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let emailPattern = "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}" // Example email regex
let guide = GenerationGuide<String>.pattern(Regex(stringLiteral: emailPattern))
// Usage with a string validator would follow...
```

### Response
#### Success Response
N/A (This is a method that returns a configuration object, not a direct response to a request)

#### Response Example
```json
{
  "guideType": "PatternValidation",
  "pattern": "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}" 
}
```
```

--------------------------------

### Wrap User Input in Prompt Format String (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

Enhances safety for open-ended user input by embedding it within a formatted prompt that explicitly instructs the model on how to respond, adding an extra layer of control.

```swift
let userInput = // The input a person enters in the app.
let prompt = """
    Generate a wholesome and empathetic journal prompt that helps \ 
    this person reflect on their day. They said: \(userInput)
    """

```

--------------------------------

### Foundation Models - errorDescription

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/errordescription

Provides a string representation of the error description for Foundation Models.

```APIDOC
## Instance Property

### errorDescription

A string representation of the error description.

**Availability:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+

```swift
var errorDescription: String? { get }
```

### Description

This property returns a human-readable string that describes the error that occurred within the Foundation Models API. It is a read-only property, meaning you can only retrieve its value.

### Method

GET (Implicitly accessed via property)

### Endpoint

N/A (Instance Property)

### Parameters

No direct parameters for accessing this property.

### Request Example

```swift
// Assuming 'model' is an instance of a Foundation Model class that can produce errors
if let error = model.error { // Replace 'error' with the actual error property if available
    let description = error.errorDescription
    print("Error description: \(description ?? \"No description available\")")
}
```

### Response

#### Success Response (Property Access)

- **errorDescription** (String?) - A string containing the error description, or nil if no error description is available.
```

--------------------------------

### Foundation Models Output Type

Source: https://developer.apple.com/documentation/foundationmodels/tool/output

Details the `Output` associated type, its requirements, and its role in the tool invocation process.

```APIDOC
## Associated Type: Output

### Description
The `Output` associated type represents the data that a tool produces for the language model to reason about in subsequent interactions. It is a crucial part of the tool's interface within the Foundation Models framework.

### Requirements
- `Output` must conform to the `PromptRepresentable` protocol.
- This type is available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

### Discussion
Typically, the `Output` is expected to be either a `String` or a `Generable` type, allowing for flexible data representation.

### Related Methods
#### `call(arguments:)`
- **Description**: A language model calls this method when it intends to use the tool. It takes `Arguments` and returns `Output`.
- **Method**: `async throws`
- **Endpoint**: N/A (Method within a protocol)

### Associated Types
#### `Arguments`
- **Description**: The `Arguments` associated type defines the structure of the input parameters that the tool accepts.
- **Requirements**: Must conform to the `ConvertibleFromGeneratedContent` protocol.
- **Required**: Yes
```

--------------------------------

### Instance Property: recoverySuggestion

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/recoverysuggestion

Retrieves a suggestion that indicates how to handle an error.

```APIDOC
## Instance Property: recoverySuggestion

### Description
A suggestion that indicates how to handle the error.

### Method
GET

### Endpoint
`/websites/developer_apple_foundationmodels/recoverySuggestion`

### Parameters

#### Query Parameters
None

### Request Example
```json
{
  "example": ""
}
```

### Response
#### Success Response (200)
- **recoverySuggestion** (String?) - A string containing the error recovery suggestion.

#### Response Example
```json
{
  "recoverySuggestion": "Please check your network connection and try again."
}
```
```

--------------------------------

### Define Tool Output: Swift

Source: https://developer.apple.com/documentation/foundationmodels/tool/arguments

Declares the `Output` associated type for a tool, defining the structure of the data returned by the tool after execution. The output must conform to the `PromptRepresentable` protocol.

```swift
associatedtype Output : PromptRepresentable

```

--------------------------------

### Transcript.Entry Enumeration

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry

Documentation for the Transcript.Entry enumeration, which represents an individual entry within a transcript. It can be instructions, a prompt, a response, or tool calls/outputs.

```APIDOC
## Transcript.Entry

### Description
An individual entry in a transcript may represent instructions from you to the model, a prompt from a user, tool calls, or a response generated by the model.

### Enumeration Cases
- **instructions** (`Transcript.Instructions`): Instructions provided by the developer.
- **prompt** (`Transcript.Prompt`): A prompt sourced from an end user.
- **response** (`Transcript.Response`): A response generated by the model.
- **toolCalls** (`Transcript.ToolCalls`): A tool call containing a tool name and its arguments.
- **toolOutput** (`Transcript.ToolOutput`): Tool output provided back to the model.

### Creating a Transcript
- `init(entries: some Sequence<Transcript.Entry>)`
  Creates a transcript from a sequence of entries.

### Conforms To
- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`
```

--------------------------------

### Transcript.StructuredSegment Structure

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment

Documentation for the Transcript.StructuredSegment structure, including its properties and initialization methods.

```APIDOC
## Transcript.StructuredSegment

A segment containing structured content.

Available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+.

### Creating a structured segment

`init(id: String, source: String, content: GeneratedContent)`

Initializes a new structured segment with a unique identifier, a source string, and the structured content.

### Inspecting a structured segment

- **`content`** (GeneratedContent) - The content of the segment.
- **`source`** (String) - A source that can be used to understand which type content represents.

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`
```

--------------------------------

### Determining Locale Support

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

Checks if a specific locale is supported by the `SystemLanguageModel`, allowing developers to ensure compatibility before attempting to use the model with that locale.

```APIDOC
## Determining whether the model supports a locale

### `func supportsLocale(Locale) -> Bool`

This method returns `true` if the provided `Locale` is supported by the language model, and `false` otherwise.
```

--------------------------------

### Handling Guardrail Errors

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails

Information on how to handle errors triggered by the system's safety guardrails.

```APIDOC
## Handling guardrail errors

* `case guardrailViolation(LanguageModelSession.GenerationError.Context)`
  An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.
```

--------------------------------

### Access Default Guardrails in Swift

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails/default

This code snippet shows how to access the default guardrails for SystemLanguageModel.Guardrails. This is a static property that returns the default guardrail configuration. This configuration is used to ensure that unsafe content in prompts and responses will be blocked.

```swift
static let `default`: SystemLanguageModel.Guardrails
```

--------------------------------

### Streaming a Response

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

Functions for streaming responses from the language model, providing partially generated content as an asynchronous sequence.

```APIDOC
## POST /websites/developer_apple_foundationmodels/stream

### Description
Produces a response stream to a prompt.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/stream`

### Parameters
#### Request Body
- **options** (GenerationOptions) - Required - Options that control how the model generates its response to a prompt.
- **prompt** (Function returning Prompt) - Required - A prompt from a person to the model.

### Request Example
```json
{
  "options": { ... },
  "prompt": "() throws -> Prompt"
}
```

### Response
#### Success Response (200)
- **ResponseStream** (LanguageModelSession.ResponseStream<String>) - An asynchronous sequence of response snapshots.

#### Response Example
```json
{
  "responseStream": [ ... ]
}
```

## POST /websites/developer_apple_foundationmodels/stream/generating

### Description
Produces a response stream for a type.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/stream/generating`

### Parameters
#### Request Body
- **generating** (Type) - Required - The type of content to stream.
- **includeSchemaInPrompt** (Boolean) - Required - Whether to include schema information in the prompt.
- **options** (GenerationOptions) - Required - Options that control how the model generates its response to a prompt.
- **prompt** (Function returning Prompt) - Required - A prompt from a person to the model.

### Request Example
```json
{
  "generating": "ContentType",
  "includeSchemaInPrompt": true,
  "options": { ... },
  "prompt": "() throws -> Prompt"
}
```

### Response
#### Success Response (200)
- **ResponseStream** (LanguageModelSession.ResponseStream<Content>) - An asynchronous sequence of response snapshots for the specified type.

#### Response Example
```json
{
  "responseStream": [ ... ]
}
```

## POST /websites/developer_apple_foundationmodels/stream/schema

### Description
Produces a response stream to a prompt and schema.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/stream/schema`

### Parameters
#### Request Body
- **schema** (GenerationSchema) - Required - The schema to guide content generation.
- **includeSchemaInPrompt** (Boolean) - Required - Whether to include schema information in the prompt.
- **options** (GenerationOptions) - Required - Options that control how the model generates its response to a prompt.
- **prompt** (Function returning Prompt) - Required - A prompt from a person to the model.

### Request Example
```json
{
  "schema": { ... },
  "includeSchemaInPrompt": true,
  "options": { ... },
  "prompt": "() throws -> Prompt"
}
```

### Response
#### Success Response (200)
- **ResponseStream** (LanguageModelSession.ResponseStream<GeneratedContent>) - An asynchronous sequence of response snapshots conforming to the schema.

#### Response Example
```json
{
  "responseStream": [ ... ]
}
```
```

--------------------------------

### Saving Feedback Data to a JSON File in Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredoutput%3A%29

Demonstrates how to combine multiple feedback attachments and save them to a single JSON Lines (`.jsonl`) file. This is the recommended method for preparing feedback data for submission using Feedback Assistant.

```swift
let allFeedback = helpfulFeedbackData + problematicFeedbackData
let url = URL(fileURLWithPath: "path/to/save/feedback.jsonl")
try allFeedback.write(to: url)
```

--------------------------------

### Generate Feedback with Text Response Swift Method

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredresponsecontent%3A%29

Logs and serializes feedback data including session information. This overloaded method variant accepts a String for the desired response text.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredResponseText: String?) -> Data
```

--------------------------------

### Prompt Inspection API

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/options

Allows inspection of a prompt's properties, including its unique identifier, desired response format, and ordered segments.

```APIDOC
## GET /websites/developer_apple_foundationmodels/prompt/inspect

### Description
Inspects the properties of a given prompt, providing details such as its ID, response format, and segments.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/prompt/inspect

### Parameters
#### Query Parameters
- **id** (String) - Required - The unique identifier of the prompt to inspect.
- **responseFormat** (Transcript.ResponseFormat) - Optional - Specifies the desired output structure for the prompt's response.

### Request Example
```
GET /websites/developer_apple_foundationmodels/prompt/inspect?id=prompt123&responseFormat=json
```

### Response
#### Success Response (200)
- **id** (String) - The identifier of the prompt.
- **responseFormat** (Transcript.ResponseFormat) - An optional response format that describes the desired output structure.
- **segments** (Array of Transcript.Segment) - Ordered prompt segments.

#### Response Example
```json
{
  "id": "prompt123",
  "responseFormat": "json",
  "segments": [
    {
      "text": "What is the capital of France?",
      "startTime": 0.5,
      "endTime": 2.0
    }
  ]
}
```
```

--------------------------------

### Log Feedback with LanguageModelSession

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

These functions are used to log feedback related to model interactions. They allow attaching session information, sentiment, issues, and desired output or response content to help improve the model. The feedback is serialized into Data.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredResponseContent: (any ConvertibleToGeneratedContent)?) -> Data
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredResponseText: String?) -> Data
```

--------------------------------

### Creating Transcript Entry from Generable Type in Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredoutput%3A%29

Shows how to create a `Transcript.Entry` when the desired output is a `Generable` type. This is used for more complex desired outputs, such as structured data, by defining a `Transcript.StructuredSegment`.

```swift
let customType = MyCustomType(...) // A generable type.
let structure = Transcript.StructuredSegment(source: String(describing: Foo.self), content: customType.generatedContent)
let segment = Transcript.Segment.structure(structure)
let response = Transcript.Response(segments: [segment])
let entry = Transcript.Entry.response(response)
```

--------------------------------

### SystemLanguageModel.Guardrails.permissiveContentTransformations

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails/permissivecontenttransformations

Configuration for permissive content transformations within the SystemLanguageModel. This guardrail allows for transforming text input, including potentially unsafe content, into text responses like summaries. It prevents `LanguageModelSession.GenerationError.guardrailViolation` errors for string generation but may still refuse unsafe prompts with an explanation. For non-string generations, it behaves like `.default`.

```APIDOC
## SystemLanguageModel.Guardrails.permissiveContentTransformations

### Description
Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.

Available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

### Method
static let 

### Endpoint
SystemLanguageModel.Guardrails.permissiveContentTransformations

### Parameters
This property does not take parameters.

### Request Example
```json
{
  "example": "N/A"
}
```

### Response
#### Success Response
- **Type**: SystemLanguageModel.Guardrails
- **Description**: The permissiveContentTransformations guardrail instance.

#### Response Example
```json
{
  "example": "SystemLanguageModel.Guardrails.permissiveContentTransformations"
}
```

### Discussion
In this mode, requests you make to the model that generate a `String` will not throw `LanguageModelSession.GenerationError.guardrailViolation` errors. However, when the purpose of your instructions and prompts is not transforming user input, the model may still refuse to respond to potentially unsafe prompts by generating an explanation. When you generate responses other than `String`, this mode behaves the same way as `.default`.

### See Also
- `static let default`: SystemLanguageModel.Guardrails
```

--------------------------------

### GenerationSchema Parameters

Source: https://developer.apple.com/documentation/foundationmodels/tool/parameters-590v0

Retrieves the GenerationSchema for the parameters accepted by the tool. This schema defines the structure and types of arguments that can be passed to the model.

```APIDOC
## GET /websites/developer_apple_foundationmodels/parameters

### Description
Retrieves the GenerationSchema for the parameters accepted by the tool. This schema defines the structure and types of arguments that can be passed to the model.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/parameters

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
- **parameters** (GenerationSchema) - A schema object defining the parameters for generation.

#### Response Example
```json
{
  "parameters": {
    "type": "object",
    "properties": {
      "prompt": {
        "type": "string",
        "description": "The input prompt for the model."
      },
      "max_tokens": {
        "type": "integer",
        "description": "The maximum number of tokens to generate."
      }
    },
    "required": [
      "prompt"
    ]
  }
}
```
```

--------------------------------

### Swift: Check if Schema is Included in Instructions

Source: https://developer.apple.com/documentation/foundationmodels/tool/includesschemaininstructions

This Swift code snippet demonstrates how to access the 'includesSchemaInInstructions' boolean property. If true, the model's name, description, and parameters schema are injected into the instructions for sessions using this tool. This property is available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

```swift
var includesSchemaInInstructions: Bool { get }
```

--------------------------------

### streamResponse(schema:includeSchemaInPrompt:options:prompt:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28schema%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

Generates a streaming response from a language model based on a provided schema, prompt, and generation options.

```APIDOC
## POST /websites/developer_apple_foundationmodels/streamResponse

### Description
Produces a response stream to a prompt and schema. This method is designed for scenarios where the output needs to conform to a specific structure defined by a schema.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/streamResponse`

### Parameters
#### Query Parameters
- **schema** (GenerationSchema) - Required - A schema to guide the output with.
- **includeSchemaInPrompt** (Bool) - Optional - Default: `true`. Inject the schema into the prompt to bias the model.
- **options** (GenerationOptions) - Optional - Default: `GenerationOptions()`. Options that control how tokens are sampled from the distribution the model produces.

#### Request Body
- **prompt** (PromptBuilder closure) - Required - A prompt for the model to respond to.

### Request Example
```json
{
  "prompt": "Generate a JSON object representing a user profile."
}
```

### Response
#### Success Response (200)
- **ResponseStream<GeneratedContent>** - A response stream that produces `GeneratedContent` containing the fields and values defined in the schema.

#### Response Example
```json
{
  "generatedContent": {
    "user": {
      "name": "John Doe",
      "age": 30,
      "email": "john.doe@example.com"
    }
  }
}
```

### Discussion
Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

**Important**: If running in the background, use the non-streaming `respond(to:options:)` method to reduce the likelihood of encountering `LanguageModelSession.GenerationError.rateLimited(_:)` errors.

### See Also
- `func streamResponse(to:options:)`
- `func streamResponse(to:generating:includeSchemaInPrompt:options:)`
- `func streamResponse(to:schema:includeSchemaInPrompt:options:)`
- `func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>`
- `func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>`
- `struct ResponseStream`
- `struct GeneratedContent`
- `protocol ConvertibleFromGeneratedContent`
- `protocol ConvertibleToGeneratedContent`
```

--------------------------------

### Create Dynamic Generation Schema

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/property

Initializes a generation schema using an array of dynamic schemas. This initializer is useful for building schemas programmatically or when dealing with schemas defined at runtime.

```swift
init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws
```

--------------------------------

### Foundation Models - constant(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/constant%28_%3A%29

Enforces that the string be precisely the given value. Available for String values and specific to iOS, iPadOS, macOS, visionOS versions 26.0 and later.

```APIDOC
## Foundation Models - constant(_:)

### Description
Enforces that the string be precisely the given value.

### Method
`static func constant(_ value: String) -> GenerationGuide<String>`

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
GenerationGuide<String>

#### Response Example
None

## See Also
### Getting the constant
`static func anyOf([String]) -> GenerationGuide<String>`
Enforces that the string be one of the provided values.
```

--------------------------------

### LanguageModelFeedback.Issue.Category Cases

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category

Lists and describes the different categories for language model response issues. Each case represents a specific type of problem, such as not following instructions, incorrect output, or bias. These cases are used to provide detailed feedback on model performance.

```swift
// The model did not follow instructions correctly.
case didNotFollowInstructions

// The model provided an incorrect response.
case incorrect

// The model exhibited bias or perpetuated a stereotype.
case stereotypeOrBias

// The model produces suggestive or sexual material.
case suggestiveOrSexual

// The response was too verbose.
case tooVerbose

// The model throws a guardrail violation when it shouldn’t.
case triggeredGuardrailUnexpectedly

// The response was not unhelpful.
case unhelpful

// The model produces vulgar or offensive material.
case vulgarOrOffensive
```

--------------------------------

### Handle LanguageModelSession Generation Refusal Error in Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal

This Swift code demonstrates how to catch a `LanguageModelSession.GenerationError.refusal` error and retrieve a textual explanation for why the language model refused to respond. It involves creating a `LanguageModelSession`, attempting a response, and then using a `catch` block to specifically handle the refusal, printing the explanation. Ensure the `MyGenerableStruct` is defined elsewhere.

```swift
do {
    let session = LanguageModelSession()
    let response = try await session.respond(to: "...", 
                                             generating: MyGenerableStruct.self)
} catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
    let message = try await refusal.explanation
    print(message)
} catch {
    print("Something went wrong: \(error)")
}
```

--------------------------------

### Tool Invocation Method: Swift

Source: https://developer.apple.com/documentation/foundationmodels/tool/arguments

Provides the signature for the `call` method used to invoke a tool with its arguments. This method is asynchronous, can throw errors, and returns the tool's output, which must conform to `PromptRepresentable`.

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output

```

--------------------------------

### Display Real-time Search Feedback in SwiftUI

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

Provides visual feedback in a SwiftUI view indicating when the model is actively searching for points of interest. It displays messages about the categories being searched.

```swift
ForEach(planner.pointOfInterestTool.lookupHistory) { element in
    HStack {
        Image(systemName: "location.magnifyingglass")
        Text("Searching **\(element.history.pointOfInterest.rawValue)** in \(landmark.name)...")
    }
    .transition(.blurReplace)
}
```

--------------------------------

### Check locale support for Foundation Models

Source: https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models

Verifies if the current locale is supported by the Foundation Models framework using the `supportsLocale()` method on `SystemLanguageModel.default`. This is crucial for ensuring the model can process and generate content in the user's preferred language or a similar supported locale.

```swift
if SystemLanguageModel.default.supportsLocale() {
    // Language is supported.
}
```

--------------------------------

### Log Feedback Attachment Swift Instance Method

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredresponsecontent%3A%29

Logs feedback data with sentiment, issues, and desired response content. This method is available across multiple Apple platforms and versions. It returns a Data object representing the serialized feedback.

```swift
@backDeployed(before: iOS 26.1, macOS 26.1, visionOS 26.1)
@discardableResult
final func logFeedbackAttachment(
    sentiment: LanguageModelFeedback.Sentiment?,
    issues: [LanguageModelFeedback.Issue] = [],
    desiredResponseContent: (any ConvertibleToGeneratedContent)?
) -> Data
```

--------------------------------

### Create a Custom Tool for Finding Points of Interest

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

Defines a custom tool, FindPointsOfInterestTool, that extends model functionality. It uses the @Observable and @Generable macros to make its properties and methods accessible to the model. The tool includes an enum for point of interest categories and a struct for arguments required by the model.

```swift
@Observable
final class FindPointsOfInterestTool: Tool {
    let name = "findPointsOfInterest"
    let description = "Finds points of interest for a landmark."
    
    let landmark: Landmark
    
    @MainActor var lookupHistory: [Lookup] = []
    
    init(landmark: Landmark) {
        self.landmark = landmark
    }


@Generable
enum Category: String, CaseIterable {
    case campground
    case hotel
    case cafe
    case museum
    case marina
    case restaurant
    case nationalMonument
}


@Generable
struct Arguments {
    @Guide(description: "This is the type of destination to look up for.")
    let pointOfInterest: Category


    @Guide(description: "The natural language query of what to search for.")
    let naturalLanguageQuery: String
}


```

--------------------------------

### On-Device Text Generation with SystemLanguageModel

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

Utilizes SystemLanguageModel for on-device text generation tasks. This class is designed to facilitate prompting an LLM for various creative and functional outputs within an application. No external dependencies are explicitly mentioned, and it directly handles model interactions.

```swift
class SystemLanguageModel
An on-device large language model capable of text generation tasks.
```

--------------------------------

### GenerationSchema.Property Initialization

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/property/init%28name%3Adescription%3Atype%3Aguides%3A%29

This section describes the initializer for creating a property within GenerationSchema, specifically for string types.

```APIDOC
## GenerationSchema.Property init(name:description:type:guides:)

### Description
Create a property that contains a string type. This initializer allows for specifying the property's name, an optional description, its type (which must be String.Type), and an array of regular expressions to guide the generated content.

### Method
Initializer

### Endpoint
N/A (This is a class initializer, not an API endpoint)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
```swift
let myProperty = GenerationSchema.Property(
    name: "propertyName",
    description: "A description for the property",
    type: String.self,
    guides: [try! Regex("^\\d{4}-\\d{2}-\\d{2}$")] // Example: YYYY-MM-DD format
)
```

### Response
#### Success Response (200)
N/A (This is a code construct, not an API response)

#### Response Example
N/A
```

--------------------------------

### Instance Property: creatorDefinedMetadata

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/creatordefinedmetadata

Retrieves values from the creator-defined field of the adapter's metadata. Available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS from version 26.0 onwards.

```APIDOC
## Instance Property: creatorDefinedMetadata

### Description
Values read from the creator-defined field of the adapter's metadata.

### Platform Availability
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+

### Property Signature
```swift
var creatorDefinedMetadata: [String : Any] { get }
```

### Returns
A dictionary of type `[String : Any]` containing the creator-defined metadata.
```

--------------------------------

### Define Transcript Entry with Tool Calls

Source: https://developer.apple.com/documentation/foundationmodels/transcript/entry/toolcalls%28_%3A%29

Defines a case within the `Transcript.Entry` enum to represent a tool call. This case holds an instance of `Transcript.ToolCalls`, which encapsulates the tool's name and its arguments. This is crucial for enabling interactions with external tools or functions based on the model's output.

```swift
case toolCalls(Transcript.ToolCalls)
```

--------------------------------

### Handle Guardrail Errors in Swift

Source: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

Demonstrates how to catch and handle `LanguageModelSession.GenerationError.guardrailViolation` errors when interacting with the Foundation Models framework. This code snippet shows the basic structure for anticipating and managing safety-related errors that occur when prompts or model outputs fail guardrail checks.

```swift
do {
    let session = LanguageModelSession()
    let topic = "// A potentially harmful topic."
    let prompt = "Write a respectful and funny story about \(topic)."
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.guardrailViolation {
    // Handle the safety error.
}
```

--------------------------------

### Streaming a Response

Source: https://developer.apple.com/documentation/foundationmodels/convertiblefromgeneratedcontent

Functions for streaming responses from a language model, with various options for content generation and schema inclusion.

```APIDOC
## Functions: Streaming a Response

### Description
These functions produce a response stream from a prompt, with options to include schema information and specify content types.

### `streamResponse` Overloads

1.  `func streamResponse(to: options:)`
    Produces a response stream to a prompt.

2.  `func streamResponse(to: generating: includeSchemaInPrompt: options:)`
    Produces a response stream to a prompt and schema.

3.  `func streamResponse(to: schema: includeSchemaInPrompt: options:)`
    Produces a response stream to a prompt and schema.

4.  `func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>`
    Produces a response stream to a prompt.

5.  `func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>`
    Produces a response stream for a type.

6.  `func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>`
    Produces a response stream to a prompt and schema.

### Related Types

*   `struct ResponseStream`
    An async sequence of snapshots of partially generated content.

*   `struct GeneratedContent`
    A type that represents structured, generated content.

*   `protocol ConvertibleToGeneratedContent`
    A type that can be converted to generated content.
```

--------------------------------

### Swift: Inspect Transcript.ToolOutput Properties

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooloutput

Provides access to the properties of a Transcript.ToolOutput instance. These include the unique identifier (`id`), the segments of the tool's output (`segments`), and the name of the tool (`toolName`).

```swift
var id: String
var segments: [Transcript.Segment]
var toolName: String
```

--------------------------------

### Swift: SystemLanguageModel.Availability.UnavailableReason.modelNotReady

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/modelnotready

This Swift code snippet represents the `modelNotReady` case for `SystemLanguageModel.Availability.UnavailableReason`. This enum case indicates that the required AI models are not currently available on the user's device, often due to automatic download conditions.

```swift
case modelNotReady
```

--------------------------------

### SystemLanguageModel.Availability.UnavailableReason.modelNotReady

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/modelnotready

This section details the 'modelNotReady' case within the SystemLanguageModel.Availability.UnavailableReason enum. It signifies that the requested models are not currently available on the user's device, often due to automatic download management based on network, battery, and system load.

```APIDOC
## SystemLanguageModel.Availability.UnavailableReason.modelNotReady

### Description
The model(s) aren’t available on the user’s device.

### Method
N/A (Enum Case)

### Endpoint
N/A (Enum Case)

### Parameters
N/A

### Request Example
N/A

### Response
#### Success Response
This enum case indicates a specific reason for unavailability.

#### Response Example
```swift
case modelNotReady
```

## Discussion
Models are downloaded automatically based on factors like network status, battery level, and system load.

## See Also
### Related Unavailable Reasons
- `case appleIntelligenceNotEnabled`
- `case deviceNotEligible`
```

--------------------------------

### LanguageModelFeedback Overview

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback

The LanguageModelFeedback namespace contains structures for describing feedback consistently. It includes Sentiment for feedback sentiment and Issue for standard issue templates. The logFeedbackAttachment function can be used with a model session to produce structured feedback.

```APIDOC
## Overview

`LanguageModelFeedback` is a namespace with structures for describing feedback in a consistent way. `LanguageModelFeedback.Sentiment` describes the sentiment of the feedback, while `LanguageModelFeedback.Issue` offers a standard template for issues.

Given a model session, use `logFeedbackAttachment(sentiment:issues:desiredOutput:)` to produce structured feedback.
```

--------------------------------

### Check Locale Support with supportsLocale(_:)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportslocale%28_%3A%29

This method returns a Boolean indicating whether the given locale is supported by the Foundation Model. It considers language fallbacks, making it a more robust check than `supportedLanguages`. It takes an optional `Locale` object, defaulting to the current locale.

```swift
final func supportsLocale(_ locale: Locale = Locale.current) -> Bool
```

--------------------------------

### Transcript Segments API

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/segments

This endpoint allows retrieval of ordered prompt segments for a transcript.

```APIDOC
## GET /websites/developer_apple_foundationmodels/transcript/segments

### Description
Retrieves ordered prompt segments associated with a transcript.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/transcript/segments

### Parameters
#### Query Parameters
- **transcriptId** (string) - Required - The identifier of the transcript.

### Request Example
(No request body for GET)

### Response
#### Success Response (200)
- **segments** ([Transcript.Segment]) - An array of ordered prompt segments.

#### Response Example
{
  "segments": [
    {
      "id": "segment1",
      "text": "This is the first segment."
    },
    {
      "id": "segment2",
      "text": "This is the second segment."
    }
  ]
}
```

--------------------------------

### GenerationOptions.SamplingMode API

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode

Details on the GenerationOptions.SamplingMode type, which controls how tokens are selected from a probability distribution during response generation.

```APIDOC
## GenerationOptions.SamplingMode

### Description
A type that defines how values are sampled from a probability distribution. It controls how a token is selected from the probability distribution generated by the model at each iteration.

### Topics

#### Sampling Options

- `static var greedy: GenerationOptions.SamplingMode`
  **Description:** A sampling mode that always chooses the most likely token.
  **Method:** Static property access

- `static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode`
  **Description:** A mode that considers a variable number of high-probability tokens based on the specified threshold.
  **Method:** Static function call
  **Parameters:**
    - `probabilityThreshold` (Double) - Required - The threshold for considering high-probability tokens.
    - `seed` (UInt64?) - Optional - A seed for random number generation.

- `static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode`
  **Description:** A sampling mode that considers a fixed number of high-probability tokens.
  **Method:** Static function call
  **Parameters:**
    - `top` (Int) - Required - The fixed number of high-probability tokens to consider.
    - `seed` (UInt64?) - Optional - A seed for random number generation.

### See Also

- `var sampling: GenerationOptions.SamplingMode?`
  **Description:** A sampling strategy for how the model picks tokens when generating a response. This property can be configured using the `GenerationOptions.SamplingMode` type.
```

--------------------------------

### Access Tool Name (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/tool/name-6x7wj

This snippet demonstrates how to access the 'name' property of a tool. The 'name' is a String representing a unique identifier for the tool, used for its identification and interaction within the Foundation Models framework. It is a read-only property.

```swift
var name: String { get }
```

--------------------------------

### Stream Response with Schema and Options - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28generating%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

Generates a response stream for a specified `Content` type. It allows including the schema in the prompt to bias the model and offers options to control token sampling. The method returns an asynchronous stream of partially generated content.

```swift
final func streamResponse<Content>(
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
) rethrows -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable
```

--------------------------------

### Read Concrete Generable Type

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/value%28_%3Aforproperty%3A%29-3xsez

Reads a concrete Generable type from a named property. This method is useful for retrieving specific data structures generated by the foundation models.

```APIDOC
## GET /websites/developer_apple_foundationmodels/value

### Description
Reads a concrete `Generable` type from a named property.

### Method
GET

### Endpoint
`/websites/developer_apple_foundationmodels/value

### Parameters
#### Query Parameters
- **property** (String) - Required - The name of the property to retrieve.
- **type** (String) - Optional - The expected type of the value. Defaults to the inferred type.

### Request Example
```json
{
  "property": "userProfile",
  "type": "UserProfile"
}
```

### Response
#### Success Response (200)
- **value** (Any) - The retrieved value, conforming to `ConvertibleFromGeneratedContent`.

#### Response Example
```json
{
  "value": {
    "name": "John Doe",
    "age": 30
  }
}
```
```

--------------------------------

### Define SystemLanguageModel.Availability.UnavailableReason Enum

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason

This code snippet shows the basic definition of the UnavailableReason enumeration. It is used to indicate why a system language model might not be available for use.

```swift
enum UnavailableReason
```

--------------------------------

### streamResponse(generating:includeSchemaInPrompt:options:prompt:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28generating%3Aincludeschemainprompt%3Aoptions%3Aprompt%3A%29

Produces a response stream for a type.

```APIDOC
## POST /websites/developer_apple_foundationmodels/streamResponse

### Description
Produces a response stream for a type, optionally including schema in the prompt and specifying generation options.

### Method
POST

### Endpoint
/websites/developer_apple_foundationmodels/streamResponse

### Parameters
#### Query Parameters
- **generating** (Type) - Required - The type to produce as the response.
- **includeSchemaInPrompt** (Boolean) - Optional - Defaults to true. Inject the schema into the prompt to bias the model.
- **options** (GenerationOptions) - Optional - Options that control how tokens are sampled from the distribution the model produces.

#### Request Body
- **prompt** (Function) - Required - A prompt for the model to respond to.

### Request Example
```json
{
  "prompt": "() throws -> Prompt"
}
```

### Response
#### Success Response (200)
- **stream** (LanguageModelSession.ResponseStream<Content>) - A response stream.

#### Response Example
```json
{
  "stream": "streaming response data"
}
```
```

--------------------------------

### Generating a Response

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession

These functions are used to generate various types of responses from the language model, including plain text, generable objects, and schema-defined content.

```APIDOC
## POST /websites/developer_apple_foundationmodels/generate

### Description
Produces a response to a prompt.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/generate`

### Parameters
#### Request Body
- **options** (GenerationOptions) - Required - Options that control how the model generates its response to a prompt.
- **prompt** (Function returning Prompt) - Required - A prompt from a person to the model.

### Request Example
```json
{
  "options": { ... },
  "prompt": "() throws -> Prompt"
}
```

### Response
#### Success Response (200)
- **Response** (LanguageModelSession.Response<String>) - The generated response as a string.

#### Response Example
```json
{
  "response": "Generated text response"
}
```

## POST /websites/developer_apple_foundationmodels/generate<Content>

### Description
Produces a generable object as a response to a prompt.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/generate<Content>`

### Parameters
#### Path Parameters
- **Content** (Type) - Required - The type of content to generate.

#### Request Body
- **includeSchemaInPrompt** (Boolean) - Required - Whether to include schema information in the prompt.
- **options** (GenerationOptions) - Required - Options that control how the model generates its response to a prompt.
- **prompt** (Function returning Prompt) - Required - A prompt from a person to the model.

### Request Example
```json
{
  "includeSchemaInPrompt": true,
  "options": { ... },
  "prompt": "() throws -> Prompt"
}
```

### Response
#### Success Response (200)
- **Response** (LanguageModelSession.Response<Content>) - The generated response as the specified generable object type.

#### Response Example
```json
{
  "response": { ... } 
}
```

## POST /websites/developer_apple_foundationmodels/generate/schema

### Description
Produces a generated content type as a response to a prompt and schema.

### Method
POST

### Endpoint
`/websites/developer_apple_foundationmodels/generate/schema`

### Parameters
#### Request Body
- **schema** (GenerationSchema) - Required - The schema to guide content generation.
- **includeSchemaInPrompt** (Boolean) - Required - Whether to include schema information in the prompt.
- **options** (GenerationOptions) - Required - Options that control how the model generates its response to a prompt.
- **prompt** (Function returning Prompt) - Required - A prompt from a person to the model.

### Request Example
```json
{
  "schema": { ... },
  "includeSchemaInPrompt": true,
  "options": { ... },
  "prompt": "() throws -> Prompt"
}
```

### Response
#### Success Response (200)
- **Response** (LanguageModelSession.Response<GeneratedContent>) - The generated response conforming to the provided schema.

#### Response Example
```json
{
  "response": { ... } 
}
```
```

--------------------------------

### Defining a Generable Type with @Generable

Source: https://developer.apple.com/documentation/foundationmodels/index

Define custom Swift data structures that the Foundation Models framework can generate instances of. This macro provides strong guarantees for structured output.

```swift
import Foundation

@Generable
struct UserProfile {
    let name: String
    let age: Int
    let bio: String
}

// Example usage:
// let generatedProfile = try await model.generate(UserProfile.self, prompt: "Create a profile for a retired astronaut.")
```

--------------------------------

### Define Generable NPC Structure in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

Defines a Swift struct 'NPC' that conforms to the 'Generable' protocol. This structure represents a Non-Player Character with properties for name, coffee order, and a visual representation (GenerableImage). It's designed to be generated by the EncounterEngine.

```swift
@Generable
struct NPC: Equatable {
    let name: String
    let coffeeOrder: String
    let picture: GenerableImage
}
```

--------------------------------

### Swift Case: assetsUnavailable

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/assetsunavailable%28_%3A%29

Defines the `assetsUnavailable` error case for `LanguageModelSession.GenerationError`. This error signifies that the necessary assets for the language model session are not available, which could stem from not checking model availability initially or from assets being deleted. Recovery might involve retrying after freeing up device storage.

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```

--------------------------------

### Represent Boolean Value with GeneratedContent.Kind.bool(_:) - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/bool%28_%3A%29

Demonstrates how to represent a boolean value using the 'GeneratedContent.Kind.bool(_:)' case. This is part of the Foundation Models framework for handling generated content. It takes a single 'Bool' parameter.

```swift
case bool(Bool)
```

--------------------------------

### Define Transcript.ToolCall Struct

Source: https://developer.apple.com/documentation/foundationmodels/transcript/toolcall

Defines the structure for a tool call generated by the model. This struct holds the name of a tool and the arguments to pass to it. Available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS version 26.0 and later.

```swift
struct ToolCall
```

--------------------------------

### Access Generated Content

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/generatedcontent

This section details how to access the generatedContent property, which provides a representation of the current instance.

```APIDOC
## GET /websites/developer_apple_foundationmodels/generatedContent

### Description
Retrieves a representation of the current instance using the generatedContent property.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/generatedContent

### Parameters
#### Query Parameters
None

### Request Example
None

### Response
#### Success Response (200)
- **generatedContent** (GeneratedContent) - A representation of the current instance.

#### Response Example
```json
{
  "generatedContent": { ... } 
}
```
```

--------------------------------

### Enforce String Pattern with Regex

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/pattern%28_%3A%29

The `pattern(_:)` static method enforces that a String value conforms to a given regular expression pattern. This method returns a `GenerationGuide<String>` and is available when the `Value` is of type `String`. It requires iOS 26.0+ or later.

```swift
static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String>
```

--------------------------------

### Associatedtype Arguments Declaration in Swift

Source: https://developer.apple.com/documentation/foundationmodels/tool/output

This Swift code snippet declares the associated type 'Arguments' for a tool, requiring it to conform to 'ConvertibleFromGeneratedContent'. This defines the structure for the input arguments that a tool can accept when invoked by a language model.

```swift
associatedtype Arguments : ConvertibleFromGeneratedContent
```

--------------------------------

### Handle Undefined References Errors (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

Represents an error when constructing a schema from dynamic schemas where one references an undefined schema. This case includes an optional schema name, a list of references, and the error context.

```swift
case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)

```

--------------------------------

### GenerationOptions.SamplingMode.random(top:seed:)

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/random%28top%3Aseed%3A%29

Configures a sampling mode that selects tokens from the top K most probable candidates. This method influences the determinism and creativity of the generated output.

```APIDOC
## GenerationOptions.SamplingMode.random(top:seed:)

### Description
A sampling mode that considers a fixed number of high-probability tokens. This is also known as top-k sampling.

### Method
`static func random(top k: Int, seed: UInt64? = nil) -> GenerationOptions.SamplingMode`

### Endpoint
N/A (This is a Swift struct/enum method)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let samplingMode = GenerationOptions.SamplingMode.random(top: 5, seed: 12345)
```

### Response
#### Success Response (N/A)
This method returns a `GenerationOptions.SamplingMode` instance.

#### Response Example
```json
{
  "samplingModeType": "random",
  "topK": 5,
  "seed": 12345
}
```

### Discussion
During the token-selection process, the vocabulary is sorted by probability, and a token is selected from among the top K candidates. Smaller values of K ensure only the most probable tokens are candidates, leading to more deterministic and confident answers. Larger values of K allow less probable tokens to be selected, increasing non-determinism and creativity.

### See Also
- `GenerationOptions.SamplingMode.greedy`
- `GenerationOptions.SamplingMode.random(probabilityThreshold:seed:)`
```

--------------------------------

### ConvertibleToGeneratedContent Protocol

Source: https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent

Details of the ConvertibleToGeneratedContent protocol, which allows types to be converted to generated content.

```APIDOC
## Protocol: ConvertibleToGeneratedContent

### Description
A type that can be converted to generated content.

Available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+.

```swift
protocol ConvertibleToGeneratedContent : InstructionsRepresentable, PromptRepresentable
```

### Topics

#### Getting the generated content

- `var generatedContent: GeneratedContent`
  This instance represented as generated content.
  **Required**

### Relationships

#### Inherits From

- `InstructionsRepresentable`
- `PromptRepresentable`

#### Inherited By

- `Generable`

### Conforming Types

- `GeneratedContent`

### See Also

#### Streaming a response

- `func streamResponse(to:options:)`
  Produces a response stream to a prompt.
- `func streamResponse(to:generating:includeSchemaInPrompt:options:)`
  Produces a response stream to a prompt and schema.
- `func streamResponse(to:schema:includeSchemaInPrompt:options:)`
  Produces a response stream to a prompt and schema.
- `func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>`
  Produces a response stream to a prompt.
- `func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>`
  Produces a response stream for a type.
- `func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>`
  Produces a response stream to a prompt and schema.

- `struct ResponseStream`
  An async sequence of snapshots of partially generated content.
- `struct GeneratedContent`
  A type that represents structured, generated content.
- `protocol ConvertibleFromGeneratedContent`
  A type that can be initialized from generated content.

Current page is ConvertibleToGeneratedContent
```

--------------------------------

### SystemLanguageModel.removeObsoleteAdapters()

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/removeobsoleteadapters%28%29

Removes all obsolete adapters that are no longer compatible with current system models. This function is available from iOS 26.0 and later.

```APIDOC
## removeObsoleteAdapters()

### Description
Removes all obsolete adapters that are no longer compatible with current system models.

### Method
`static func` (implies a static method call, often associated with a class or struct)

### Endpoint
N/A (This appears to be a method within a framework, not a REST API endpoint)

### Parameters
None

### Request Example
```swift
try SystemLanguageModel.removeObsoleteAdapters()
```

### Response
#### Success Response
This method indicates success by not throwing an error. The adapters are removed if they are obsolete.

#### Response Example
N/A (Success is indicated by the absence of an error being thrown.)

### Availability
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+
```

--------------------------------

### Define Structured Content with GeneratedContent.Kind.structure

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/structure%28properties%3Aorderedkeys%3A%29

This Swift code defines a structured content type using the GeneratedContent.Kind.structure case. It takes a dictionary of properties and an ordered list of keys to represent key-value data. This is useful for organizing and presenting complex generated information.

```swift
case structure(
    properties: [String : GeneratedContent],
    orderedKeys: [String]
)
```

--------------------------------

### Transcript.Prompt.id

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/id

Retrieves the unique identifier for a transcript prompt.

```APIDOC
## Transcript.Prompt.id

### Description
The identifier of the prompt.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/id

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
- **id** (String) - The unique identifier of the prompt.

#### Response Example
```json
{
  "id": "unique_prompt_identifier"
}
```

### Platform Availability
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+
```

--------------------------------

### Represent String Value with GeneratedContent.Kind.string(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/string%28_%3A%29

This Swift code snippet demonstrates how to represent a string value using the GeneratedContent.Kind.string case. This case is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS versions 26.0 and later.

```swift
case string(String)
```

--------------------------------

### Other Generation Errors

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/guardrailviolation%28_%3A%29

A collection of other potential generation errors within the LanguageModelSession, each indicating a specific failure condition.

```APIDOC
## Other Generation Errors

### Description
This section details various other errors that can occur during a language model generation session, providing context for each.

### Method
N/A (Enum Cases)

### Endpoint
N/A (Enum Cases)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A

---

### `case assetsUnavailable(LanguageModelSession.GenerationError.Context)`
An error that indicates the assets required for the session are unavailable.

### `case decodingFailure(LanguageModelSession.GenerationError.Context)`
An error that indicates the session failed to deserialize a valid generable type from model output.

### `case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`
An error that signals the session reached its context window size limit.

### `case rateLimited(LanguageModelSession.GenerationError.Context)`
An error that indicates your session has been rate limited.

### `case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`
An error that happens when the session refuses the request.

### `case concurrentRequests(LanguageModelSession.GenerationError.Context)`
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

### `case unsupportedGuide(LanguageModelSession.GenerationError.Context)`
An error that indicates a generation guide with an unsupported pattern was used.

### `case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.
```

--------------------------------

### SystemLanguageModel.Adapter.AssetError.invalidAdapterName(_:)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror/invalidadaptername%28_%3A%29

Represents an error condition where the provided adapter name is invalid. This error is part of the SystemLanguageModel.Adapter.AssetError enum.

```APIDOC
## SystemLanguageModel.Adapter.AssetError.invalidAdapterName(_:)

### Description
An error that happens if the provided adapter name is invalid.

### Method
N/A (Enum Case)

### Endpoint
N/A (Enum Case)

### Parameters
#### Path Parameters
N/A

#### Query Parameters
N/A

#### Request Body
N/A

### Request Example
N/A

### Response
#### Success Response (200)
N/A

#### Response Example
N/A
```

--------------------------------

### Swift: Declare Source Property for Foundation Models

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment/source

This Swift code snippet declares the 'source' instance property, a String, used to identify the origin of content within Foundation Models. It is compatible with iOS 26.0 and later.

```swift
var source: String
```

--------------------------------

### Define Transcript Structure

Source: https://developer.apple.com/documentation/foundationmodels/transcript

Defines the `Transcript` structure, which represents a linear history of entries in a Foundation Models session. This structure is fundamental for managing and visualizing the interaction flow between a user, the model, and any tools used.

```swift
struct Transcript
```

--------------------------------

### Swift: random Sampling Mode with Top K Tokens

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/greedy

Introduces a `random` sampling mode for `GenerationOptions.SamplingMode` that considers a fixed number of top tokens. This mode selects from the 'top K' most probable tokens, offering a balance between determinism and variety.

```swift
static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode
```

--------------------------------

### Associatedtype Output Declaration in Swift

Source: https://developer.apple.com/documentation/foundationmodels/tool/output

This Swift code snippet declares the associated type 'Output' for a model or tool, specifying that it must conform to the 'PromptRepresentable' protocol. This defines the expected structure for the data returned by the model or tool.

```swift
associatedtype Output : PromptRepresentable
```

--------------------------------

### Handle Empty Type Choices Errors (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

Represents an error when constructing an anyOf schema with an empty array of type choices. This case includes the schema name and the error context.

```swift
case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)

```

--------------------------------

### Related Types

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment

Overview of types related to Transcript.StructuredSegment, such as Instructions, Prompt, Response, and various segment and tool-related structures.

```APIDOC
## Related Types

### Getting the transcript types

- **`Instructions`** (`struct`): Instructions provided to the model that define its behavior.
- **`Prompt`** (`struct`): A prompt from the user to the model.
- **`Response`** (`struct`): A response from the model.
- **`ResponseFormat`** (`struct`): Specifies a response format that the model must conform its output to.
- **`TextSegment`** (`struct`): A segment containing text.
- **`ToolCall`** (`struct`): A tool call generated by the model containing the name of a tool and arguments to pass to it.
- **`ToolCalls`** (`struct`): A collection of tool calls generated by the model.
- **`ToolDefinition`** (`struct`): A definition of a tool.
- **`ToolOutput`** (`struct`): A tool output provided back to the model.
```

--------------------------------

### Swift: random Sampling Mode with Probability Threshold

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/greedy

Provides a `random` sampling mode for `GenerationOptions.SamplingMode` that uses a probability threshold. This mode considers a variable number of high-probability tokens based on the provided threshold, allowing for more diverse outputs than greedy sampling.

```swift
static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode
```

--------------------------------

### Swift: Initialize StructuredSegment

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment

Initializes a structured segment with a unique identifier, a source string, and generated content. This is used to create instances of structured segments for use in transcript processing.

```swift
init(id: String, source: String, content: GeneratedContent)
```

--------------------------------

### Swift: Define minimum array count with minimumCount(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generationguide/minimumcount%28_%3A%29

Demonstrates how to use `minimumCount(_:)` to enforce a minimum number of elements in an array property within a `@Generable` struct. This is useful for ensuring collections, like `inventory`, meet a certain size requirement.

```swift
static func minimumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

@Generable
struct Shop {
    @Guide(description: "A creative name for a shop in a fantasy RPG")
    var name: String

    @Guide(description: "A list of items for sale", .minimumCount(3))
    var inventory: [ShopItem]
}
```

--------------------------------

### Disable Schema Inclusion in Foundation Model Prompts (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/analyzing-the-runtime-performance-of-your-foundation-models-app

This code snippet demonstrates how to set the `includeSchemaInPrompt` parameter to `false` within `GenerationOptions` for a `LanguageModelSession`. Disabling schema inclusion reduces token consumption by excluding redundant schema information from prompts, which can improve performance and stay within context limits. This is particularly useful when schema information has already been provided or is not necessary for subsequent requests.

```swift
let response = try await session.streamResponse(
    prompt: prompt,
    generable: MyCustomItinerary.self,
    options: .init(includeSchemaInPrompt: false)
)

```

--------------------------------

### Swift: greedy Sampling Mode for GenerationOptions

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/greedy

Defines the `greedy` static property for `GenerationOptions.SamplingMode`. This mode always selects the most likely token, resulting in deterministic outputs. It's suitable for scenarios requiring consistent results but may lack the natural variation found in other sampling strategies.

```swift
static var greedy: GenerationOptions.SamplingMode { get }
```

--------------------------------

### Initialize ToolCallError

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror

Initializes a ToolCallError instance. This initializer requires the tool that caused the error and the underlying error object.

```swift
init(tool: any Tool, underlyingError: any Error)
```

--------------------------------

### Stream Response with Content Type and Schema - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse%28to%3Agenerating%3Aincludeschemainprompt%3Aoptions%3A%29

This Swift function streams a response from a language model to a given prompt, specifying the expected content type and optionally including a schema to bias the model's output. It returns an asynchronous stream of `LanguageModelSession.ResponseStream<Content>`, where `Content` must conform to the `Generable` protocol. Options for token sampling can also be provided.

```swift
final func streamResponse<Content>(
    to prompt: Prompt,
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
) -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable
```

--------------------------------

### Handle Duplicate Property Errors (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

Represents an error when constructing a dynamic schema with conflicting property names. This case includes the schema name, the duplicate property name, and the error context.

```swift
case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)

```

--------------------------------

### GeneratedContent.Kind.string(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/string%28_%3A%29

Represents a string value. This case is used to define content that is of a string type.

```APIDOC
## GeneratedContent.Kind.string(_:)

### Description
Represents a string value. This case is used to define content that is of a string type.

### Method
Not applicable (enum case)

### Endpoint
Not applicable (enum case)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```json
{
  "kind": "string",
  "value": "example string"
}
```

### Response
#### Success Response (200)
Represents a string value within the GeneratedContent.Kind enum.

#### Response Example
```json
{
  "case": "string",
  "value": "example string"
}
```

## See Also
- `case array([GeneratedContent])`: Represents an array of `GeneratedContent` elements.
- `case bool(Bool)`: Represents a boolean value.
- `case null`: Represents a null value.
- `case number(Double)`: Represents a numeric value.
- `case structure(properties: [String : GeneratedContent], orderedKeys: [String])`: Represents a structured object with key-value pairs.
```

--------------------------------

### Convert to Partially Generated Content: asPartiallyGenerated()

Source: https://developer.apple.com/documentation/foundationmodels/generable/partiallygenerated

Provides a method to convert the current struct into its associated `PartiallyGenerated` type. This function is part of the default implementations for types conforming to the necessary protocols.

```swift
func asPartiallyGenerated() -> Self.PartiallyGenerated
```

--------------------------------

### Swift: Generate Sampling Mode with Probability Threshold

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/random%28probabilitythreshold%3Aseed%3A%29

This Swift code defines a static method `random` within `GenerationOptions.SamplingMode` that generates a sampling mode based on a probability threshold. It allows for dynamic selection of tokens by considering a variable number of high-probability tokens until their cumulative probability exceeds the specified threshold. An optional seed can be provided for deterministic results.

```swift
static func random(
    probabilityThreshold: Double,
    seed: UInt64? = nil
) -> GenerationOptions.SamplingMode
```

--------------------------------

### Foundation Models - debugDescription Property

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/debugdescription

Provides a string representation of the debug description for Foundation Models. This property is not localized and should not be displayed to end users.

```APIDOC
## Foundation Models - debugDescription Property

### Description
A string representation of the debug description for a Foundation Model instance. This string is intended for debugging purposes only and is not localized.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/debugDescription

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
None

### Response
#### Success Response (200)
- **debugDescription** (String) - A non-localized string providing debugging information.

#### Response Example
```json
{
  "debugDescription": "A detailed string for debugging purposes."
}
```
```

--------------------------------

### Foundation Models - rawContent

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/rawcontent

Accesses the raw content of a response generated by the Foundation Models API. This property is available from iOS 26.0 and later versions of iPadOS, Mac Catalyst, macOS, and visionOS.

```APIDOC
## Instance Property: rawContent

### Description
The raw content of the response.

### Availability
iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, visionOS 26.0+

### Syntax
```swift
var rawContent: GeneratedContent
```

### Discussion
When `Content` is `GeneratedContent`, this is the same as `content`.

### See Also
- `content`: The content of the response (`Content.PartiallyGenerated`).
```

--------------------------------

### Access Foundation Model Parameters Schema (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/tool/parameters-590v0

Retrieves the schema defining the accepted parameters for a Foundation Model tool. This property is available on iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+. It is accessible when the `Arguments` type conforms to the `Generable` protocol.

```swift
var parameters: GenerationSchema { get }
```

--------------------------------

### Inspect Response Format Name - Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/responseformat

Retrieves the name associated with a ResponseFormat. This property provides a string identifier for the specific format being used, useful for debugging or logging purposes.

```swift
var name: String
```

--------------------------------

### Swift DynamicGenerationSchema Structure

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema

Defines the basic structure of DynamicGenerationSchema in Swift. This is a fundamental type for constructing schemas at runtime within the Foundation Models framework.

```swift
struct DynamicGenerationSchema
```

--------------------------------

### Define AssetError Enumeration

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror

Defines the AssetError enumeration used for adapter-related errors in the System Language Model. This enumeration conforms to Swift's Error protocol, providing a structured way to handle specific failure conditions.

```swift
enum AssetError
```

--------------------------------

### Check if Apple Intelligence is Not Enabled (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/appleintelligencenotenabled

This snippet demonstrates how to check for the 'appleIntelligenceNotEnabled' reason for unavailability within the SystemLanguageModel.Availability.UnavailableReason enum. This check is crucial for handling scenarios where Apple Intelligence features cannot be used because the system setting is disabled.

```swift
case appleIntelligenceNotEnabled
```

--------------------------------

### Swift: Access GeneratedContent Properties

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent

Provides access to the properties of a GeneratedContent instance, including its kind, completion status, JSON string representation, debug description, and unique generation ID.

```swift
var kind: GeneratedContent.Kind
```

```swift
var isComplete: Bool
```

```swift
var jsonString: String
```

```swift
var debugDescription: String
```

```swift
var id: GenerationID?
```

--------------------------------

### Swift: Set Foundation Model Temperature

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/temperature

This Swift code snippet demonstrates how to set the 'temperature' property for a foundation model. The temperature value, a Double between 0 and 1, influences the model's response confidence and creativity. Leaving it nil allows the system to use a default value.

```swift
var temperature: Double?
```

--------------------------------

### Handle Duplicate Type Errors (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

Represents an error when constructing a schema from dynamic schemas with duplicate type names. This case includes optional schema name, the duplicate type name, and the error context.

```swift
case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)

```

--------------------------------

### GeneratedContent ID Property

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/id

Details the 'id' property of the GeneratedContent class, which is a unique and stable identifier for generated responses. It explains when the 'id' is non-nil (during streaming) and when it is nil (for manually created instances).

```APIDOC
## GeneratedContent `id` Property

### Description
A unique identifier that remains stable for the duration of a generated response. This property is particularly relevant when streaming responses from a `LanguageModelSession`.

### Method
N/A (Instance Property)

### Endpoint
N/A

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```json
{
  "example": "This section is not applicable for a property description."
}
```

### Response
#### Success Response (200)
- **id** (GenerationID?) - A stable unique ID for the generated response. This will be non-nil for streamed responses and nil for manually initialized `GeneratedContent` objects.

#### Response Example
```json
{
  "id": "some-stable-generation-id"
}
```

### Discussion
A `LanguageModelSession` produces instances of `GeneratedContent` that have a non-nil `id`. When you stream a response, the `id` is the same for all partial generations in the response stream. Instances of `GeneratedContent` that you produce manually with initializers have a nil `id` because the framework didn’t create them as part of a generation.
```

--------------------------------

### Accessing isComplete Property (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/iscomplete

This snippet demonstrates how to access the `isComplete` Boolean property of a GeneratedContent instance. This property indicates if the content generation process has been completed. It requires no specific inputs and returns a boolean value.

```swift
var isComplete: Bool { get }
```

--------------------------------

### Initialize Transcript.TextSegment

Source: https://developer.apple.com/documentation/foundationmodels/transcript/textsegment

Initializes a TextSegment instance with a unique identifier and its textual content. This is the primary method for creating text segments.

```swift
init(id: String, content: String)
```

--------------------------------

### LanguageModelSession.collect()

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/collect%28%29

Retrieves the completed result from a streaming response. This method is available for streaming responses where the 'Content' type conforms to 'Generable'. It returns the response immediately if the stream completed successfully before calling, or propagates any errors encountered during the stream.

```APIDOC
## LanguageModelSession.collect()

### Description
Retrieves the completed result from a streaming response after it has finished.

### Method
`async throws`

### Endpoint
N/A (Instance Method)

### Parameters
None

### Request Example
N/A (Instance Method)

### Response
#### Success Response (200)
- **Response** (`LanguageModelSession.Response<Content>`) - The completed response object.

#### Response Example
```json
{
  "example": "response body"
}
```

## Discussion
If the streaming response was finished successfully before calling `collect()`, this method `Response` returns immediately. If the streaming response was finished with an error before calling `collect()`, this method propagates that error.
```

--------------------------------

### Swift: Accessing Transcript Entries

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response

Retrieves the list of transcript entries associated with a model response. This property is an array slice of `Transcript.Entry` objects, available within the LanguageModelSession.Response structure.

```swift
let transcriptEntries: ArraySlice<Transcript.Entry>

```

--------------------------------

### GenerationOptions.SamplingMode.greedy

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/greedy

The greedy sampling mode always selects the most probable next token. This results in deterministic output but may lack the natural variation found in other sampling methods.

```APIDOC
## GenerationOptions.SamplingMode.greedy

### Description
A sampling mode that always chooses the most likely token.

### Method
`static var greedy: GenerationOptions.SamplingMode { get }`

### Platform Availability
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+

### Discussion
Using this mode will always result in the same output for a given input. Responses produced with greedy sampling are statistically likely, but may lack the human-like quality and variety of other sampling strategies.

### See Also
- `static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode`
- `static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode`
```

--------------------------------

### Log Feedback Attachment Function

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment

Logs and serializes data for feedback submission, including session information. It accepts an optional sentiment, a list of issues, and the desired output, returning the serialized data.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
```

--------------------------------

### Access Foundation Model Transcript (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/transcript

The 'transcript' property provides access to a full history of interactions within a Foundation Model session. This includes both user inputs and the model's responses. It is a read-only property.

```swift
final var transcript: Transcript { get }
```

--------------------------------

### ConvertibleToGeneratedContent Protocol Definition

Source: https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent

Defines a type that can be converted into generated content. This protocol requires conformance to InstructionsRepresentable and PromptRepresentable.

```swift
protocol ConvertibleToGeneratedContent : InstructionsRepresentable, PromptRepresentable {}
```

--------------------------------

### Check Model Response Status with isResponding (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/isresponding

This Swift code demonstrates how to use the `isResponding` property to disable a button and prevent the user from submitting a new request while the model is already generating a response. It uses a `LanguageModelSession` to handle the interaction with Foundation Models. Ensure that the `isResponding` property is checked before calling any respond methods to avoid race conditions.

```swift
struct ShopView: View {
    @State var session = LanguageModelSession()
    @State var joke = ""


    var body: some View {
        Text(joke)
        Button("Generate joke") {
            Task {
                assert(!session.isResponding, "It should not be possible to tap this button while the model is responding")
                joke = try await session.respond(to: "Tell me a joke").content
            }
        }
        .disabled(session.isResponding) // Prevent concurrent calls to respond
    }
}
```

--------------------------------

### Accessing Response Content (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/content

This code snippet demonstrates how to access the 'content' property of a LanguageModelSession.Response object. The 'content' property returns the response content of type 'Content'. This is a read-only property.

```swift
let responseContent: Content = response.content
```

--------------------------------

### Define Tool Arguments: Swift

Source: https://developer.apple.com/documentation/foundationmodels/tool/arguments

Defines the `Arguments` associated type for a tool, specifying the structure of input arguments the tool accepts. It must conform to `ConvertibleFromGeneratedContent` and is typically a `Generable` type or `GeneratedContent`.

```swift
associatedtype Arguments : ConvertibleFromGeneratedContent

```

--------------------------------

### LanguageModelFeedback.Issue.Category

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/unhelpful

This section lists various categories for reporting issues with language model responses, including didNotFollowInstructions, incorrect, stereotypeOrBias, suggestiveOrSexual, tooVerbose, triggeredGuardrailUnexpectedly, and vulgarOrOffensive.

```APIDOC
## LanguageModelFeedback.Issue.Category

### Description
This API allows users to categorize specific issues encountered with language model responses. Each category represents a distinct type of problem that the model might exhibit.

### Method
N/A (This is a descriptive enum, not a direct API endpoint)

### Endpoint
N/A

### Parameters
N/A

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A

### See Also
* `case didNotFollowInstructions`: The model did not follow instructions correctly.
* `case incorrect`: The model provided an incorrect response.
* `case stereotypeOrBias`: The model exhibited bias or perpetuated a stereotype.
* `case suggestiveOrSexual`: The model produces suggestive or sexual material.
* `case tooVerbose`: The response was too verbose.
* `case triggeredGuardrailUnexpectedly`: The model throws a guardrail violation when it shouldn’t.
* `case vulgarOrOffensive`: The model produces vulgar or offensive material.
* `case unhelpful`: The response was not helpful.
```

--------------------------------

### Access Failure Reason

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror

Retrieves a string that explains the underlying reason for the LanguageModelSession.GenerationError. This property is also part of the LocalizedError protocol.

```swift
var failureReason: String?
```

--------------------------------

### LanguageModelFeedback.Issue.Category Enum

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue

Details the possible categories for issues identified in a language model's response.

```APIDOC
## Enum: LanguageModelFeedback.Issue.Category

### Description
Represents the different categories of issues that can occur with a model's response.

### Fields
* **Data_format**
* **Bias**
* **Factuality**
* **Hallucination**
* **Safety**
* **Other**
```

--------------------------------

### Integrate MapKit for Location Lookup and Weather

Source: https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

Combines generative model features with MapKit to perform location lookups and retrieve weather information. The `LocationLookup` class handles searching for addresses and fetching associated weather data.

```swift
@Observable @MainActor
final class LocationLookup {
    private(set) var item: MKMapItem?
    private(set) var temperatureString: String?


    func performLookup(location: String) {
        Task {
            let item = await self.mapItem(atLocation: location)
            if let location = item?.location {
                self.temperatureString = await self.weather(atLocation: location)
            }
        }
    }
    
    private func mapItem(atLocation location: String) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = location
        
        let search = MKLocalSearch(request: request)
        do {
            return try await search.start().mapItems.first
        } catch {
            Logging.general.error("Failed to look up location: \(location). Error: \(error)")
        }
        return nil
    }
}
```

--------------------------------

### Generation Schema Property

Source: https://developer.apple.com/documentation/foundationmodels/generable/generationschema

Access the generation schema instance for Foundation Models.

```APIDOC
## GET /websites/developer_apple_foundationmodels/generationSchema

### Description
Retrieves an instance of the generation schema, which describes the properties of an object and guides on their values.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/generationSchema

### Parameters
This endpoint does not have any path, query, or request body parameters.

### Request Example
```json
{
  "example": "No request body needed for this GET request."
}
```

### Response
#### Success Response (200)
- **generationSchema** (GenerationSchema) - An instance of the generation schema.

#### Response Example
```json
{
  "generationSchema": {
    "type": "object",
    "properties": {
      "exampleProperty": {
        "type": "string",
        "description": "An example property"
      }
    }
  }
}
```
```

--------------------------------

### maximumResponseTokens Instance Property

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/maximumresponsetokens

The maximumResponseTokens property allows you to set an upper limit on the number of tokens a model can generate. This helps prevent excessively long responses and manage generation costs.

```APIDOC
## maximumResponseTokens Instance Property

### Description
The maximum number of tokens the model is allowed to produce in its response.

### Method
Instance Property

### Endpoint
N/A (Instance Property)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
var maximumResponseTokens: Int?
```

### Response
#### Success Response (200)
N/A (Instance Property)

#### Response Example
N/A (Instance Property)

### Discussion
If the model produces `maximumResponseTokens` before it naturally completes its response, the response will be terminated early. No error will be thrown. This property can be used to protect against unexpectedly verbose responses and runaway generations.

If no value is specified, then the model is allowed to produce the longest answer its context size supports. If the response exceeds that limit without terminating, an error will be thrown.
```

--------------------------------

### Constrain Input with Enum Options (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

Restricts user input by providing a fixed set of options through an enumeration, ensuring prompts stay within defined topics and reducing safety risks from unverified external sources.

```swift
enum TopicOptions {
    case family
    case nature
    case work 
}
let topicChoice = TopicOptions.nature
let prompt = """
    Generate a wholesome and empathetic journal prompt that helps \ 
    this person reflect on \(topicChoice)
    """

```

--------------------------------

### Transcript.Segment Enumeration

Source: https://developer.apple.com/documentation/foundationmodels/transcript/segment

Documentation for the Transcript.Segment enumeration, which defines the types of segments that can be included in a transcript entry.

```APIDOC
## Transcript.Segment Enum

### Description
The types of segments that may be included in a transcript entry.

### Topics
#### Creating a segment
- `case structure(Transcript.StructuredSegment)`: A segment containing structured content.
- `case text(Transcript.TextSegment)`: A segment containing text.

### Relationships
#### Conforms To
- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

### See Also
#### Creating a transcript
- `init(entries: some Sequence<Transcript.Entry>)`: Creates a transcript.
- `enum Entry`: An entry in a transcript.
```

--------------------------------

### LanguageModelSession.GenerationError.recoverySuggestion

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/recoverysuggestion

The recoverySuggestion property returns a string that offers a suggestion on how to recover from a generation error encountered with the Foundation Models API.

```APIDOC
## LanguageModelSession.GenerationError.recoverySuggestion

### Description
A string representation of the recovery suggestion.

### Method
GET

### Endpoint
N/A (Instance Property)

### Parameters
None

### Request Example
None

### Response
#### Success Response (200)
- **recoverySuggestion** (String?) - A string representation of the recovery suggestion.

#### Response Example
```json
{
  "recoverySuggestion": "Try rephrasing your prompt or providing more context."
}
```
```

--------------------------------

### Create Object Schema with Properties

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/property

Constructs a generation schema for an object type by providing an array of `GenerationSchema.Property`. This is used to define complex object structures with multiple named fields.

```swift
init(type: Any.Type, description: String?, properties: [GenerationSchema.Property])
```

--------------------------------

### Read Generable Type - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/value%28_%3A%29

This method reads a top-level, concrete partially `Generable` type from a named property. It requires the generic `Value` type to conform to `ConvertibleFromGeneratedContent`. This method is available on iOS 26.0+ and compatible platforms.

```swift
func value<Value>(_ type: Value.Type = Value.self) throws -> Value where Value : ConvertibleFromGeneratedContent
```

--------------------------------

### Retrieve Error Description (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/errordescription

The errorDescription property returns an optional String representing the detailed description of an error. This is a read-only property, meaning it can only be accessed and not modified directly. It is part of the Foundation Models framework.

```swift
var errorDescription: String? { get }
```

--------------------------------

### Foundation Models - Transcript Segment

Source: https://developer.apple.com/documentation/foundationmodels/transcript/tooloutput/segments

Retrieves segments of the tool output for foundation models. This is an instance property of the Transcript object.

```APIDOC
## GET /websites/developer_apple_foundationmodels/segments

### Description
Retrieves segments of the tool output associated with foundation models. This property is part of the Transcript object and provides structured data about the output generated by a tool.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/segments

### Parameters
None

### Request Example
```json
{
  "message": "Request to retrieve transcript segments."
}
```

### Response
#### Success Response (200)
- **segments** (array) - An array of Transcript.Segment objects, each representing a segment of the tool's output.

#### Response Example
```json
{
  "segments": [
    {
      "id": "segment_1",
      "text": "This is the first segment of the output.",
      "startTime": 0.5,
      "endTime": 2.3
    },
    {
      "id": "segment_2",
      "text": "This is the second segment.",
      "startTime": 2.5,
      "endTime": 4.1
    }
  ]
}
```
```

--------------------------------

### Representing Null Value in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/null

This Swift code snippet demonstrates the declaration of the 'null' case for GeneratedContent.Kind. This case is used to represent a null value. It is directly usable in Swift code.

```swift
case null
```

--------------------------------

### LanguageModelSession.GenerationError.guardrailViolation(_:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/guardrailviolation%28_%3A%29

Represents an error where the system's safety guardrails are triggered by either the prompt or the model's generated response.

```APIDOC
## LanguageModelSession.GenerationError.guardrailViolation(_:)

### Description
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

### Method
N/A (Enum Case)

### Endpoint
N/A (Enum Case)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
N/A

### Response
#### Success Response (N/A)
N/A

#### Response Example
N/A
```

--------------------------------

### Access rawContent - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/rawcontent

The rawContent property returns the raw content of the response as a GeneratedContent object. This is identical to the 'content' property when the content is of type Content.PartiallyGenerated. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS from version 26.0 onwards.

```swift
var rawContent: GeneratedContent
```

--------------------------------

### Swift Generable Macro Declaration

Source: https://developer.apple.com/documentation/foundationmodels/generable%28description%3A%29

Declares the `Generable` macro, which can optionally accept a `description` string. It's an attached macro that conforms types to `Generable` and adds members.

```swift
@attached(extension, conformances: Generable, names: named(init(_:)), named(generatedContent)) @attached(member, names: arbitrary)
macro Generable(description: String? = nil)
```

--------------------------------

### Swift Enum Case for Device Not Eligible

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/devicenoteligible

This Swift code snippet demonstrates the enum case `deviceNotEligible` used to signify that a device does not support Apple Intelligence. This is a direct representation of the unavailability reason.

```swift
case deviceNotEligible
```

--------------------------------

### Swift DynamicGenerationSchema Property Structure

Source: https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema

Defines the structure for a property within a dynamic generation schema. This is used when constructing object schemas dynamically.

```swift
struct Property
```

--------------------------------

### LanguageModelSession.failureReason

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/failurereason

Retrieves a string representation of the failure reason for a LanguageModelSession.

```APIDOC
## GET /websites/developer_apple_foundationmodels/LanguageModelSession/failureReason

### Description
This endpoint returns a string representation of the failure reason for a LanguageModelSession.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/LanguageModelSession/failureReason

### Parameters
#### Query Parameters
None

### Request Example
```
// No request body for GET requests
```

### Response
#### Success Response (200)
- **failureReason** (String?) - A string representation of the failure reason.

#### Response Example
```json
{
  "failureReason": "Model execution failed due to invalid input."
}
```
```

--------------------------------

### Log Feedback Attachment Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment%28sentiment%3Aissues%3Adesiredoutput%3A%29

Logs and serializes feedback data for a language model session, including sentiment, specific issues, and desired output. This method is crucial for reporting issues and improving model performance.

```swift
@discardableResult
final func logFeedbackAttachment(
    sentiment: LanguageModelFeedback.Sentiment?,
    issues: [LanguageModelFeedback.Issue] = [],
    desiredOutput: Transcript.Entry? = nil
) -> Data
```

--------------------------------

### Generable Protocol Definition - Swift

Source: https://developer.apple.com/documentation/foundationmodels/generable

This Swift code defines the 'Generable' protocol, which is essential for enabling AI models to generate instances of custom types. It inherits from several other protocols, indicating its role in content conversion and prompt representation. The protocol itself does not contain implementation details but outlines the expected capabilities for types that can be generated.

```swift
protocol Generable : ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent {}
```

--------------------------------

### Accessing failureReason Property (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/failurereason

This Swift code snippet demonstrates how to access the 'failureReason' instance property of a LanguageModelSession object. It retrieves a string that describes why a language model operation might have failed. This property is optional and will be nil if no failure occurred.

```swift
var failureReason: String? { get }
```

--------------------------------

### Access Error Description

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror

Retrieves a human-readable string representation of the error description for a LanguageModelSession.GenerationError. This property is part of the LocalizedError protocol.

```swift
var errorDescription: String?
```

--------------------------------

### Create Enumeration Schema

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/property

Creates a generation schema for a string enumeration. This allows defining a property that accepts only specific string values from a predefined list.

```swift
init(type: String, description: String?, anyOf: [String])
```

--------------------------------

### Swift: Inspect StructuredSegment Properties

Source: https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment

Provides access to the content and source properties of a structured segment. The 'content' property holds the generated content, while 'source' indicates the origin of the content, aiding in understanding its context.

```swift
var content: GeneratedContent
var source: String
```

--------------------------------

### Define invalidAdapterName Error - Swift

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror/invalidadaptername%28_%3A%29

This Swift code defines the `invalidAdapterName` error case for `SystemLanguageModel.Adapter.AssetError`. This error is raised when an invalid adapter name is provided to the system language model adapter. It requires a `Context` object detailing the error's circumstances. The case is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS from version 26.0 onwards.

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```

--------------------------------

### jsonString Property

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/jsonstring

The `jsonString` property returns a JSON string representation of the `GeneratedContent` object.

```APIDOC
## jsonString Property

### Description
Returns a JSON string representation of the generated content.

### Availability
iOS 26.0+ iPadOS 26.0+ Mac Catalyst 26.0+ macOS 26.0+ visionOS 26.0+

### Syntax
```swift
var jsonString: String { get }
```

### Examples

#### Creating GeneratedContent and accessing jsonString

```swift
// Object with properties
let content = GeneratedContent(properties: [
    "name": "Johnny Appleseed",
    "age": 30,
])
print(content.jsonString)
// Output: {"name": "Johnny Appleseed", "age": 30}
```

### See Also

- `var kind: GeneratedContent.Kind`
- `var isComplete: Bool`
```

--------------------------------

### GenerationSchema.SchemaError.emptyTypeChoices Swift Case

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/emptytypechoices%28schema%3Acontext%3A%29

Represents an error when attempting to construct an `anyOf` schema with an empty array of type choices. This case requires the `schema` (a String) and `context` (of type `GenerationSchema.SchemaError.Context`) as parameters.

```swift
case emptyTypeChoices(
    schema: String,
    context: GenerationSchema.SchemaError.Context
)
```

--------------------------------

### Access ToolCallError Properties

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror

Provides access to the properties of a ToolCallError instance. These include the tool that generated the error, a string description of the error, and the original underlying error.

```swift
var tool: any Tool
var errorDescription: String?
var underlyingError: any Error
```

--------------------------------

### Set Maximum Response Tokens (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/maximumresponsetokens

The `maximumResponseTokens` property allows you to define the upper limit for the number of tokens a Foundation Model can generate in its response. Setting this value can prevent unexpectedly verbose outputs or runaway generations. If the model reaches this limit before completing its response, it will be terminated early without an error. If unspecified, the model will generate up to its context size limit, potentially throwing an error if exceeded.

```swift
var maximumResponseTokens: Int?
```

--------------------------------

### LanguageModelFeedback.Issue.Category.didNotFollowInstructions

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

Report an issue where the model failed to follow instructions correctly. Applicable across multiple Apple platforms.

```APIDOC
## LanguageModelFeedback.Issue.Category.didNotFollowInstructions

### Description
This category is used to report instances where the language model did not adhere to the provided instructions or constraints.

### Method
POST (Assumed)

### Endpoint
/v1/feedback/issues/categories/didNotFollowInstructions (Assumed)

### Parameters
#### Request Body
- **issue_details** (string) - Required - A detailed explanation of how the model failed to follow instructions.
- **user_prompt** (string) - Required - The prompt given to the model.
- **model_response** (string) - Required - The response generated by the model.

### Request Example
```json
{
  "issue_details": "The model was asked to provide a concise summary, but instead gave a verbose answer.",
  "user_prompt": "Summarize the following text in under 50 words.",
  "model_response": "[Long and detailed summary exceeding 50 words]"
}
```

### Response
#### Success Response (200)
- **message** (string) - Confirmation that the feedback has been received.

#### Response Example
```json
{
  "message": "Feedback successfully submitted."
}
```
```

--------------------------------

### Access Transcript Segments in Swift

Source: https://developer.apple.com/documentation/foundationmodels/transcript/instructions/segments

This code snippet demonstrates how to access the 'segments' property of a Transcript object in Swift. The 'segments' property returns an array of Transcript.Segment objects, representing the natural language content of the instructions. This functionality requires iOS, iPadOS, macOS, or visionOS version 26.0 or later.

```swift
var segments: [Transcript.Segment]
```

--------------------------------

### SystemLanguageModel.Guardrails.permissiveContentTransformations Declaration

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails/permissivecontenttransformations

This code snippet declares the `permissiveContentTransformations` static constant within the `SystemLanguageModel.Guardrails` type. It is available on iOS, iPadOS, Mac Catalyst, macOS, and visionOS versions 26.0 and later.

```swift
static let permissiveContentTransformations: SystemLanguageModel.Guardrails
```

--------------------------------

### GenerationOptions.SamplingMode.random(top:seed:)

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/random%28probabilitythreshold%3Aseed%3A%29

A sampling mode that considers a fixed number of high-probability tokens.

```APIDOC
## POST /websites/developer_apple_foundationmodels/GenerationOptions/SamplingMode/random_top

### Description
Creates a sampling mode that considers a fixed number of high-probability tokens.

### Method
POST

### Endpoint
/websites/developer_apple_foundationmodels/GenerationOptions/SamplingMode/random_top

### Parameters
#### Query Parameters
- **top** (Int) - Required - The number of high-probability tokens to consider.
- **seed** (UInt64) - Optional - An optional random seed used to make output more deterministic.

### Request Example
```json
{
  "top": 5,
  "seed": 67890
}
```

### Response
#### Success Response (200)
- **samplingMode** (GenerationOptions.SamplingMode) - The created sampling mode.

#### Response Example
```json
{
  "samplingMode": "random(top: 5, seed: 67890)"
}
```
```

--------------------------------

### GenerationOptions.SamplingMode.greedy

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/random%28probabilitythreshold%3Aseed%3A%29

A sampling mode that always chooses the most likely token.

```APIDOC
## GET /websites/developer_apple_foundationmodels/GenerationOptions/SamplingMode/greedy

### Description
Returns a sampling mode that always chooses the most likely token.

### Method
GET

### Endpoint
/websites/developer_apple_foundationmodels/GenerationOptions/SamplingMode/greedy

### Parameters
None

### Request Example
```json
{}
```

### Response
#### Success Response (200)
- **samplingMode** (GenerationOptions.SamplingMode) - The greedy sampling mode.

#### Response Example
```json
{
  "samplingMode": "greedy"
}
```
```

--------------------------------

### LanguageModelSession.GenerationError.errorDescription

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/errordescription

Retrieves a string representation of the error description for a generation error within the LanguageModelSession.

```APIDOC
## LanguageModelSession.GenerationError.errorDescription

### Description
A string representation of the error description.

### Method
GET

### Endpoint
N/A (Instance Property)

### Parameters
None

### Request Example
None

### Response
#### Success Response (200)
- **errorDescription** (String?) - A string representation of the error description.

#### Response Example
```json
{
  "errorDescription": "An error occurred during generation."
}
```
```

--------------------------------

### Swift Case: unhelpful

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/triggeredguardrailunexpectedly

Represents a scenario where the language model's response is unhelpful. This case is part of the `LanguageModelFeedback.Issue.Category` enum.

```swift
case unhelpful
```

--------------------------------

### Swift: Handle Concurrent Request Error in LanguageModelSession

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/concurrentrequests%28_%3A%29

This Swift code snippet demonstrates the `concurrentRequests` error case within `LanguageModelSession.GenerationError`. It is used to catch and handle situations where a new prompt is sent to a language model session that is already busy processing a previous request. This prevents race conditions and ensures proper session management.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```

--------------------------------

### GenerationOptions.SamplingMode.random(probabilityThreshold:seed:)

Source: https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/random%28probabilitythreshold%3Aseed%3A%29

Creates a sampling mode that considers a variable number of high-probability tokens based on the specified threshold (nucleus sampling).

```APIDOC
## POST /websites/developer_apple_foundationmodels/GenerationOptions/SamplingMode/random

### Description
Creates a sampling mode that considers a variable number of high-probability tokens based on the specified threshold. This is also known as top-p or nucleus sampling.

### Method
POST

### Endpoint
/websites/developer_apple_foundationmodels/GenerationOptions/SamplingMode/random

### Parameters
#### Query Parameters
- **probabilityThreshold** (Double) - Required - A number between 0.0 and 1.0 that increases sampling pool size.
- **seed** (UInt64) - Optional - An optional random seed used to make output more deterministic.

### Request Example
```json
{
  "probabilityThreshold": 0.9,
  "seed": 12345
}
```

### Response
#### Success Response (200)
- **samplingMode** (GenerationOptions.SamplingMode) - The created sampling mode.

#### Response Example
```json
{
  "samplingMode": "random(probabilityThreshold: 0.9, seed: 12345)"
}
```
```

--------------------------------

### Declare responseFormat Property (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/transcript/prompt/responseformat

This Swift code snippet declares the 'responseFormat' instance property. It is an optional property of type 'Transcript.ResponseFormat', allowing developers to specify a desired output structure for transcripts. This property is available from iOS 26.0 and later.

```swift
var responseFormat: Transcript.ResponseFormat?
```

--------------------------------

### LanguageModelFeedback.Issue.Category.unhelpful

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

Report an issue where the model's response was unhelpful. Applicable across multiple Apple platforms.

```APIDOC
## LanguageModelFeedback.Issue.Category.unhelpful

### Description
Use this category when the model's response does not provide useful information or assist the user effectively.

### Method
POST (Assumed)

### Endpoint
/v1/feedback/issues/categories/unhelpful (Assumed)

### Parameters
#### Request Body
- **issue_details** (string) - Required - Explanation of why the response was unhelpful.

### Request Example
```json
{
  "issue_details": "The model provided a generic answer that did not address the specific question asked."
}
```

### Response
#### Success Response (200)
- **message** (string) - Confirmation that the feedback has been received.

#### Response Example
```json
{
  "message": "Feedback successfully submitted."
}
```
```

--------------------------------

### GenerationSchema.SchemaError Context Struct (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

Defines the context in which a GenerationSchema.SchemaError occurred. This struct is used within the various error cases of the SchemaError enumeration.

```swift
struct Context

```

--------------------------------

### LanguageModelFeedback.Sentiment.neutral

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment/neutral

Represents a neutral sentiment feedback for language models. This is a simple case enumeration.

```APIDOC
## LanguageModelFeedback.Sentiment.neutral

### Description
Represents a neutral sentiment for language model feedback. This case is used when the sentiment is neither positive nor negative.

### Method
N/A (This is an enumeration case, not an API endpoint)

### Endpoint
N/A

### Parameters
N/A

### Request Example
N/A

### Response
N/A

### See Also
- `LanguageModelFeedback.Sentiment.negative`: Represents a negative sentiment.
- `LanguageModelFeedback.Sentiment.positive`: Represents a positive sentiment.
```

--------------------------------

### GeneratedContent.Kind.number(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/number%28_%3A%29

Represents a numeric value of type Double within the GeneratedContent.Kind enumeration.

```APIDOC
## GeneratedContent.Kind.number(_:)

### Description
Represents a numeric value as a Double.

### Method
`case number(Double)`

### Endpoint
N/A (Enum case definition)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let numericKind = GeneratedContent.Kind.number(123.45)
```

### Response
#### Success Response (200)
N/A (Enum case definition)

#### Response Example
N/A (Enum case definition)

### See Also
- `case array([GeneratedContent])`
- `case bool(Bool)`
- `case null`
- `case string(String)`
- `case structure(properties: [String : GeneratedContent], orderedKeys: [String])`
```

--------------------------------

### Sentiment Cases for LanguageModelFeedback.Sentiment

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment

Represents the different sentiment categories for a language model's response: negative, neutral, or positive. These are standard enum cases conforming to various protocols like CaseIterable and Equatable.

```swift
case negative
case neutral
case positive
```

--------------------------------

### Swift: Define Text Segment in Transcript

Source: https://developer.apple.com/documentation/foundationmodels/transcript/segment/text%28_%3A%29

This Swift code defines the `text` case for `Transcript.Segment`, indicating a segment that holds plain text content. It takes a `Transcript.TextSegment` as its associated value. This is part of the Foundation Models framework.

```swift
case text(Transcript.TextSegment)
```

--------------------------------

### LanguageModelSession.GenerationError.decodingFailure(_:)

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/decodingfailure%28_%3A%29

Represents an error where the session failed to deserialize a valid generable type from the model's output. This can occur if the generation process was terminated prematurely.

```APIDOC
## LanguageModelSession.GenerationError.decodingFailure(_:)

### Description
An error that indicates the session failed to deserialize a valid generable type from model output. This can happen if generation was terminated early.

### Method
N/A (Enum Case)

### Endpoint
N/A (Enum Case)

### Parameters
#### Associated Values
- **Context** (LanguageModelSession.GenerationError.Context) - The context in which the error occurred.

### Request Example
```json
{
  "error": "decodingFailure",
  "context": {
    "details": "Model output could not be deserialized."
  }
}
```

### Response
#### Success Response (N/A - Enum Case)
This represents an error condition, not a successful API response.

#### Response Example
(See Request Example - this is an error structure)

### See Also
- `LanguageModelSession.GenerationError.assetsUnavailable(LanguageModelSession.GenerationError.Context)`
- `LanguageModelSession.GenerationError.exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`
- `LanguageModelSession.GenerationError.guardrailViolation(LanguageModelSession.GenerationError.Context)`
- `LanguageModelSession.GenerationError.rateLimited(LanguageModelSession.GenerationError.Context)`
- `LanguageModelSession.GenerationError.refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`
- `LanguageModelSession.GenerationError.concurrentRequests(LanguageModelSession.GenerationError.Context)`
- `LanguageModelSession.GenerationError.unsupportedGuide(LanguageModelSession.GenerationError.Context)`
- `LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

### Related Structures
- `struct Context`
- `struct Refusal`
```

--------------------------------

### Define Transcript Segment Type

Source: https://developer.apple.com/documentation/foundationmodels/transcript/segment

Defines an enumeration for segment types within a transcript. Supports structured and text segments, applicable across various Apple platforms from iOS 26.0 onwards.

```swift
enum Segment
```

--------------------------------

### Access Underlying Error in Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror/underlyingerror

This code snippet demonstrates how to access the 'underlyingError' property of a LanguageModelSession object in Swift. It allows developers to retrieve the original error that occurred during a tool call for debugging purposes. No specific dependencies are required beyond the FoundationModels framework.

```swift
var underlyingError: any Error
```

--------------------------------

### Define Negative Sentiment Case

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment/negative

This snippet demonstrates how to define a 'negative' sentiment case. It is a simple declaration used to represent negative feedback or sentiment in language models. No specific dependencies are listed, and it serves as a direct enumeration value.

```swift
case negative
```

--------------------------------

### Swift: Read Value from GeneratedContent

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent

Enables reading a top-level, concrete value from a named property within the GeneratedContent. This function allows extraction of specific data types based on their concrete type.

```swift
func value<Value>(Value.Type) throws -> Value
```

```swift
func value(_:forProperty:)
```

--------------------------------

### LanguageModelFeedback.Issue.Category.tooVerbose

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

Report an issue where the model's response was too verbose. Applicable across multiple Apple platforms.

```APIDOC
## LanguageModelFeedback.Issue.Category.tooVerbose

### Description
Report when the model's response is excessively long or contains unnecessary information, making it too verbose.

### Method
POST (Assumed)

### Endpoint
/v1/feedback/issues/categories/tooVerbose (Assumed)

### Parameters
#### Request Body
- **issue_details** (string) - Required - Explanation of why the response was considered too verbose.

### Request Example
```json
{
  "issue_details": "The response included lengthy background information not requested by the prompt."
}
```

### Response
#### Success Response (200)
- **message** (string) - Confirmation that the feedback has been received.

#### Response Example
```json
{
  "message": "Feedback successfully submitted."
}
```
```

--------------------------------

### Swift: Related LanguageModelFeedback Issue Categories

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/didnotfollowinstructions

This Swift code snippet illustrates various other categories for reporting issues with language models, including 'incorrect' responses, 'stereotypeOrBias', 'suggestiveOrSexual' content, 'tooVerbose' responses, unexpected 'triggeredGuardrailUnexpectedly' violations, 'unhelpful' output, and 'vulgarOrOffensive' material.

```swift
case incorrect
case stereotypeOrBias
case suggestiveOrSexual
case tooVerbose
case triggeredGuardrailUnexpectedly
case unhelpful
case vulgarOrOffensive
```

--------------------------------

### Declare invalidAsset Error - Swift

Source: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror/invalidasset%28_%3A%29

This code snippet demonstrates the declaration of the `invalidAsset` error case within the `SystemLanguageModel.Adapter.AssetError` enum. It is used to signify an error condition where provided asset files are invalid. This requires iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, or visionOS 26.0+.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```

--------------------------------

### GeneratedContent.Kind.null Case

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/null

This section details the `null` case within the `GeneratedContent.Kind` enum, which signifies a null value.

```APIDOC
## GeneratedContent.Kind.null

### Description
Represents a null value.

### Availability
iOS 26.0+
iPadOS 26.0+
Mac Catalyst 26.0+
macOS 26.0+
visionOS 26.0+

### Case Declaration
```swift
case null
```

### See Also
- `case array([GeneratedContent])`: Represents an array of `GeneratedContent` elements.
- `case bool(Bool)`: Represents a boolean value.
- `case number(Double)`: Represents a numeric value.
- `case string(String)`: Represents a string value.
- `case structure(properties: [String : GeneratedContent], orderedKeys: [String])`: Represents a structured object with key-value pairs.
```

--------------------------------

### GeneratedContent.Kind Swift Enum Definition

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift

This snippet shows the basic definition of the GeneratedContent.Kind enumeration in Swift. It serves as a fundamental type for representing different kinds of generated content within the FoundationModels framework.

```swift
enum Kind
```

--------------------------------

### Declare Transcript.TextSegment Structure

Source: https://developer.apple.com/documentation/foundationmodels/transcript/textsegment

Declares the basic TextSegment structure used for holding text content. This structure is a core component for representing textual data within the FoundationModels framework.

```swift
struct TextSegment
```

--------------------------------

### Guardrail Violation Error Case

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/guardrailviolation%28_%3A%29

Represents an error where the system's safety guardrails are triggered by content within a prompt or the model's generated response. This case requires a `Context` object detailing the error circumstances.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```

--------------------------------

### Swift: GenerationSchema.SchemaError.duplicateProperty Definition

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/duplicateproperty%28schema%3Aproperty%3Acontext%3A%29

Defines the `duplicateProperty` case within `GenerationSchema.SchemaError`. This error is triggered when attempting to create a dynamic schema with properties that share the same name, indicating a conflict. It captures the schema name, the conflicting property name, and the error context.

```swift
case duplicateProperty(
    schema: String,
    property: String,
    context: GenerationSchema.SchemaError.Context
)
```

--------------------------------

### LanguageModelFeedback.Issue.Category.suggestiveOrSexual

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

Report an issue where the model produces suggestive or sexual material. Applicable across multiple Apple platforms.

```APIDOC
## LanguageModelFeedback.Issue.Category.suggestiveOrSexual

### Description
Use this category to report content generated by the model that is suggestive or sexual in nature.

### Method
POST (Assumed)

### Endpoint
/v1/feedback/issues/categories/suggestiveOrSexual (Assumed)

### Parameters
#### Request Body
- **issue_details** (string) - Required - A description of the suggestive or sexual content.

### Request Example
```json
{
  "issue_details": "The model generated a response with inappropriate innuendo."
}
```

### Response
#### Success Response (200)
- **message** (string) - Confirmation that the feedback has been received.

#### Response Example
```json
{
  "message": "Feedback successfully submitted."
}
```
```

--------------------------------

### Declare LanguageModelSession.GenerationError.decodingFailure

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/decodingfailure%28_%3A%29

This Swift code snippet declares the `decodingFailure` case for the `LanguageModelSession.GenerationError` enum. It signifies a failure during the deserialization of model output and requires a `Context` object detailing the error.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```

--------------------------------

### Define LanguageModelFeedback.Issue.Category Enum

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category

Defines an enumeration for categorizing issues related to language model responses. This is a fundamental type for reporting feedback on model behavior. It conforms to several standard Swift protocols for broader usability.

```swift
enum Category
```

--------------------------------

### Define GenerationSchema.SchemaError Enum (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

Defines the SchemaError enumeration for handling generation schema creation errors. This enum has cases for duplicate properties, duplicate types, empty type choices, and undefined references. It requires iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, or visionOS 26.0+.

```swift
enum SchemaError

```

--------------------------------

### GeneratedContent.Kind.bool(_:)

Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/bool%28_%3A%29

Represents a boolean value within the GeneratedContent.Kind enum. This case is used to denote a boolean type.

```APIDOC
## GeneratedContent.Kind.bool(_:)

### Description
Represents a boolean value. This case is used to signify a boolean type within the `GeneratedContent.Kind` enum.

### Method
Not applicable (enum case definition).

### Endpoint
Not applicable (enum case definition).

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
let booleanValue: GeneratedContent.Kind = .bool(true)
```

### Response
#### Success Response (200)
Not applicable (enum case definition).

#### Response Example
```json
{
  "type": "boolean",
  "value": true
}
```

## Parameters 

`value` 
    
The boolean value. (Bool) - Required

## See Also

### Getting the kind of content
* `case array([GeneratedContent])`
* `case null`
* `case number(Double)`
* `case string(String)`
* `case structure(properties: [String : GeneratedContent], orderedKeys: [String])`
```

--------------------------------

### Define ToolCallError Structure

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror

Defines the structure for ToolCallError, which represents an error occurring during a tool call by a language model. This structure conforms to standard Swift error protocols.

```swift
struct ToolCallError
```

--------------------------------

### Swift Case: incorrect

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/triggeredguardrailunexpectedly

Represents a scenario where the language model produces an incorrect response. This case is part of the `LanguageModelFeedback.Issue.Category` enum.

```swift
case incorrect
```

--------------------------------

### Collect Streaming Response - Swift

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/collect%28%29

The collect() method retrieves the final result from a streaming response after it has completed. If the stream finished successfully, it returns a Response object. If an error occurred during the stream, this method propagates that error. This function is available for types conforming to Generable.

```swift
nonisolated(nonsending)
func collect() async throws -> sending LanguageModelSession.Response<Content>
```

--------------------------------

### GenerationSchema.SchemaError.duplicateProperty

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/duplicateproperty%28schema%3Aproperty%3Acontext%3A%29

An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.

```APIDOC
## GenerationSchema.SchemaError.duplicateProperty(schema:property:context:)

### Description
An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.

### Method
Not applicable (this is an error type definition)

### Endpoint
Not applicable (this is an error type definition)

### Parameters
#### Path Parameters
None

#### Query Parameters
None

#### Request Body
None

### Request Example
```swift
// Example of how this error might be thrown (conceptual)
let error = GenerationSchema.SchemaError.duplicateProperty(
    schema: "MySchema",
    property: "conflictingProperty",
    context: GenerationSchema.SchemaError.Context(...)
)
```

### Response
#### Success Response (200)
Not applicable (this is an error type definition)

#### Response Example
Not applicable (this is an error type definition)
```

--------------------------------

### Related Schema Errors

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/duplicateproperty%28schema%3Aproperty%3Acontext%3A%29

Details on other schema errors within the GenerationSchema.SchemaError type.

```APIDOC
## Related Schema Errors

### `case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)`
An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.

### `case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)`
An error that represents an attempt to construct an anyOf schema with an empty array of type choices.

### `case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)`
An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.

### `struct Context`
The context in which the error occurred.
```

--------------------------------

### Swift Case for Positive Sentiment

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment/positive

This Swift code snippet defines the 'positive' case for LanguageModelFeedback.Sentiment. It represents a positive sentiment and is part of the LanguageModelFeedback API.

```swift
case positive
```

--------------------------------

### LanguageModelFeedback.Issue.Category.vulgarOrOffensive

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/vulgaroroffensive

Represents an issue where the language model produces vulgar or offensive material. This is applicable for iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

```APIDOC
## LanguageModelFeedback.Issue.Category.vulgarOrOffensive

### Description
The model produces vulgar or offensive material.

### Method
Not Applicable (enum case)

### Endpoint
Not Applicable (enum case)

### Parameters
Not Applicable (enum case)

### Request Example
Not Applicable (enum case)

### Response
#### Success Response (200)
Not Applicable (enum case)

#### Response Example
Not Applicable (enum case)

## See Also
### Getting the issue category
- `case didNotFollowInstructions`
- `case incorrect`
- `case stereotypeOrBias`
- `case suggestiveOrSexual`
- `case tooVerbose`
- `case triggeredGuardrailUnexpectedly`
- `case unhelpful`
```

--------------------------------

### Declare GenerationID in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generationid

Defines the basic structure for GenerationID. This declaration is fundamental for using the identifier within the Foundation Models framework. No specific inputs or outputs are associated with this declaration itself.

```swift
struct GenerationID
```

--------------------------------

### Swift Case: tooVerbose

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/triggeredguardrailunexpectedly

Represents a scenario where the language model's response is excessively verbose. This case is part of the `LanguageModelFeedback.Issue.Category` enum.

```swift
case tooVerbose
```

--------------------------------

### LanguageModelFeedback.Issue.Category.incorrect

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

Report an issue where the model provided an incorrect response. Applicable across multiple Apple platforms.

```APIDOC
## LanguageModelFeedback.Issue.Category.incorrect

### Description
This category is for reporting factual inaccuracies or incorrect information provided by the language model.

### Method
POST (Assumed)

### Endpoint
/v1/feedback/issues/categories/incorrect (Assumed)

### Parameters
#### Request Body
- **issue_details** (string) - Required - A description of the incorrect information provided.
- **correct_information** (string) - Optional - The accurate information, if known.

### Request Example
```json
{
  "issue_details": "The model stated that the capital of Australia is Sydney, which is incorrect.",
  "correct_information": "The capital of Australia is Canberra."
}
```

### Response
#### Success Response (200)
- **message** (string) - Confirmation that the feedback has been received.

#### Response Example
```json
{
  "message": "Feedback successfully submitted."
}
```
```

--------------------------------

### Constrain Output with Generable Enum (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

Limits the model's output to a predefined set of safe options using the '@Generable' attribute on an enum, providing stronger safety guarantees when handling freeform user input.

```swift
@Generable
enum Breakfast {
    case waffles
    case pancakes
    case bagels
    case eggs 
}
let session = LanguageModelSession()
let userInput = "I want something sweet."
let prompt = "Pick the ideal breakfast for request: \(userInput)"
let response = try await session.respond(to: prompt, generating: Breakfast.self)

```

--------------------------------

### Associated Type Declaration: PartiallyGenerated

Source: https://developer.apple.com/documentation/foundationmodels/generable/partiallygenerated

Declares the `PartiallyGenerated` associated type for a type conforming to `ConvertibleFromGeneratedContent`. This allows specifying a custom type for partially generated content, with `Self` as the default.

```swift
associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self
```

--------------------------------

### Swift: GenerationSchema.SchemaError.duplicateType Case

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/duplicatetype%28schema%3Atype%3Acontext%3A%29

Defines the `duplicateType` error case within `GenerationSchema.SchemaError`. This error is thrown when attempting to build a schema from dynamic schemas, and multiple subschemas are found to have the same type name. It includes optional schema information, the duplicate type name, and the error context.

```swift
case duplicateType(
    schema: String?,
    type: String,
    context: GenerationSchema.SchemaError.Context
)
```

--------------------------------

### Access Transcript.TextSegment Content

Source: https://developer.apple.com/documentation/foundationmodels/transcript/textsegment

Provides read-only access to the textual content stored within a TextSegment instance. This property allows retrieval of the segment's text.

```swift
var content: String
```

--------------------------------

### Swift: Declare rateLimited Error in LanguageModelSession

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/ratelimited%28_%3A%29

This Swift code snippet declares the `rateLimited` error case for `LanguageModelSession.GenerationError`. It is used to indicate that a language model session has been rate-limited, often occurring when an app exceeds background processing limits.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```

--------------------------------

### LanguageModelFeedback.Issue.Category.triggeredGuardrailUnexpectedly

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

Report an issue where the model triggered a guardrail violation when it should not have. Applicable across multiple Apple platforms.

```APIDOC
## LanguageModelFeedback.Issue.Category.triggeredGuardrailUnexpectedly

### Description
This category is for reporting instances where a safety guardrail was activated inappropriately or unnecessarily by the model's response.

### Method
POST (Assumed)

### Endpoint
/v1/feedback/issues/categories/triggeredGuardrailUnexpectedly (Assumed)

### Parameters
#### Request Body
- **issue_details** (string) - Required - Description of the prompt and why the guardrail activation was unexpected.
- **user_prompt** (string) - Required - The prompt that led to the guardrail activation.

### Request Example
```json
{
  "issue_details": "The model refused to answer a harmless question about a historical event, citing safety concerns.",
  "user_prompt": "Tell me about the Battle of Waterloo."
}
```

### Response
#### Success Response (200)
- **message** (string) - Confirmation that the feedback has been received.

#### Response Example
```json
{
  "message": "Feedback successfully submitted."
}
```
```

--------------------------------

### LanguageModelFeedback.Issue.Category.vulgarOrOffensive

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

Report an issue where the model produces vulgar or offensive material. Applicable across multiple Apple platforms.

```APIDOC
## LanguageModelFeedback.Issue.Category.vulgarOrOffensive

### Description
This category is for reporting content generated by the model that is vulgar, offensive, or inappropriate.

### Method
POST (Assumed)

### Endpoint
/v1/feedback/issues/categories/vulgarOrOffensive (Assumed)

### Parameters
#### Request Body
- **issue_details** (string) - Required - Description of the vulgar or offensive content.

### Request Example
```json
{
  "issue_details": "The model used offensive language in its response."
}
```

### Response
#### Success Response (200)
- **message** (string) - Confirmation that the feedback has been received.

#### Response Example
```json
{
  "message": "Feedback successfully submitted."
}
```
```

--------------------------------

### Swift: Define Suggestive or Sexual Issue Category

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/suggestiveorsexual

This Swift code snippet demonstrates how to define the `suggestiveOrSexual` case for the `LanguageModelFeedback.Issue.Category` enum. This case is used to report when a language model produces suggestive or sexual material. It requires iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, or visionOS 26.0+.

```swift
case suggestiveOrSexual
```

--------------------------------

### Swift: Define Unsupported Language or Locale Error

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/unsupportedlanguageorlocale%28_%3A%29

Defines the `unsupportedLanguageOrLocale` case within the `LanguageModelSession.GenerationError` enum. This specific error is triggered when the language model is prompted to generate content in a language or locale it does not support. It includes a context object detailing the error's occurrence.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```

--------------------------------

### Swift: Define Structured Transcript Segment

Source: https://developer.apple.com/documentation/foundationmodels/transcript/segment/structure%28_%3A%29

Defines a case named `structure` within the `Transcript.Segment` enum. This case holds an instance of `Transcript.StructuredSegment`, representing a segment of a transcript that contains structured data. This is a common pattern for enumerating different types of segments within a transcript.

```swift
case structure(Transcript.StructuredSegment)
```

--------------------------------

### LanguageModelFeedback.Issue.Category.stereotypeOrBias

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/stereotypeorbias

Report an issue where the model exhibited bias or perpetuated a stereotype. This is applicable for iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, and visionOS 26.0+.

```APIDOC
## LanguageModelFeedback.Issue.Category.stereotypeOrBias

### Description
This category is used to report issues where the language model has exhibited bias or perpetuated a stereotype in its response.

### Method
POST (Assumed)

### Endpoint
/v1/feedback/issues/categories/stereotypeOrBias (Assumed)

### Parameters
#### Request Body
- **issue_details** (string) - Required - A detailed description of the observed bias or stereotype.
- **model_version** (string) - Optional - The version of the foundation model used.
- **platform** (string) - Optional - The platform where the issue was observed (e.g., iOS, macOS).

### Request Example
```json
{
  "issue_details": "The model summarized an article by a male author but used male pronouns without explicitly mentioning the author's gender, implying a default.",
  "model_version": "2.1.0",
  "platform": "iOS"
}
```

### Response
#### Success Response (200)
- **message** (string) - Confirmation that the feedback has been received.

#### Response Example
```json
{
  "message": "Feedback successfully submitted."
}
```
```

--------------------------------

### Define Undefined References Schema Error in Swift

Source: https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/undefinedreferences%28schema%3Areferences%3Acontext%3A%29

This Swift code defines the `undefinedReferences` case for the `GenerationSchema.SchemaError` enum. It signifies an error during schema construction when a dynamic schema references another schema that is not defined. It includes optional schema name, an array of referenced schema names, and the error context.

```swift
case undefinedReferences(
    schema: String?,
    references: [String],
    context: GenerationSchema.SchemaError.Context
)
```

--------------------------------

### Swift Case: vulgarOrOffensive

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/triggeredguardrailunexpectedly

Represents a scenario where the language model generates vulgar or offensive material. This case is part of the `LanguageModelFeedback.Issue.Category` enum.

```swift
case vulgarOrOffensive
```

--------------------------------

### Define PartiallyGenerated Type Alias (Swift)

Source: https://developer.apple.com/documentation/foundationmodels/generable/partiallygenerated-swift

This code snippet defines a type alias named 'PartiallyGenerated' which is an alias for 'Self'. It is used to represent partially generated content. This definition is common in Swift protocols and structures.

```swift
typealias PartiallyGenerated = Self
```

--------------------------------

### Swift Case: stereotypeOrBias

Source: https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category/triggeredguardrailunexpectedly

Represents a scenario where the language model exhibits bias or perpetuates a stereotype. This case is part of the `LanguageModelFeedback.Issue.Category` enum.

```swift
case stereotypeOrBias
```

=== COMPLETE CONTENT === This response contains all available snippets from this library. No additional content exists. Do not make further requests.
