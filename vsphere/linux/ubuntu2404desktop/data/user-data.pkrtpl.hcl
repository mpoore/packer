#cloud-config

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Ubuntu Desktop 24.04.1 LTS

autoinstall:
  version: 1
  source:
    id: ubuntu-mate-desktop-minimal
  identity:
    hostname: ubuntu2404desktop
    username: ${build_username}
    password: "${build_password_encrypted}"
  ssh:
    install-server: true
    allow-pw: true
  packages:
  - open-vm-tools