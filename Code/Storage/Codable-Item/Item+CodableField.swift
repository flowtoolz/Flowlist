extension Tree where Data == ItemData
{
    enum CodableField: String, CodingKey
    {
        case id, text = "title", state, tag, subitems = "subtasks"
    }
}
