import {
  lia
} from './logger'

class LiaStorage {
  constructor (channel = null) {
    if (!channel) return

    this.channel = channel
    this._init()
  }

  _init () {
    if (!this.channel) return

    let store = this._setLocal

    this.channel.push('lia', {
      get_local_storage: []
    })
      .receive('ok', (e) => {
        store(e)
      })
      .receive('error', (e) => {
        lia.error('storing => ', e)
      })
  }

  getItems (key = []) {
    if (typeof key === 'string') key = [key]

    let rslt = {}
    for (let i = 0; i < key.length; i++) {
      let value = localStorage.getItem(key[i])

      rslt[key[i]] = value ? JSON.parse(value) : value
    }

    return rslt
  }

  setItems (dict) {
    if (this.channel) {
      this.channel.push('lia', {
        set_local_storage: dict
      })
    }

    this._setLocal(dict)
  }

  _setLocal (dict) {
    if (typeof dict === 'object') {
      for (const [key, value] of Object.entries(dict)) {
        localStorage.setItem(key, JSON.stringify(value))
      }
    }
  }
};

export {
  LiaStorage
}
