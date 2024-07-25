# A Simple nvim Plugin for Easily Utilizing All Available Registers

## Setup:

```lua
--- Lazy
return {
    keys = {
        {
            "<C-y>",
            "<cmd>PastedY<cr>",
            mode = { "x" },
        },
        {
            "<leader>v",
            "<cmd>Pastedp<cr>",
        },
    },
    opts = {},
}
```

