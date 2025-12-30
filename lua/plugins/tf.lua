return {
  {
    'allaman/tf.nvim',
    opts = {
      doc = {
        providers = {
          libvirt = { namespace = 'dmacvicar' },
          talos = { namespace = 'siderolabs' },
        },
      },
    },
    ft = 'terraform',
  },
}
